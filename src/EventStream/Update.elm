module EventStream.Update exposing (resetEventStreamIfSourceChanged, update)

import Dict
import EventStream.Message exposing (..)
import EventStream.Model exposing (errorLens, etagLens, eventsLens, sourceLens)
import GitHub.APIv3 exposing (readGitHubEvents, readGitHubEventsNextPage)
import GitHub.Message
import GitHub.Model exposing (GitHubEvent, GitHubEventSource(..), GitHubEventsChunk, GitHubResponse)
import Http
import Model exposing (Authorization, Model, eventStreamErrorLens, eventStreamEventsLens, eventStreamSourceLens, limitsLens, timelineEventsLens)
import Time exposing (posixToMillis)
import Url
import Util exposing (..)


update : Msg -> Authorization -> Model -> ( Model, Cmd Msg )
update msg auth model =
    case msg of
        ReadEvents ->
            ( model
            , Cmd.batch
                [ readGitHubEvents model.eventStream.source model.eventStream.etag auth
                    |> Cmd.map GitHubResponseEvents
                ]
            )

        ReadEventsNextPage url ->
            ( model
            , Cmd.batch
                [ readGitHubEventsNextPage url model.eventStream.etag auth
                    |> Cmd.map GitHubResponseEvents
                ]
            )

        GitHubResponseEvents (GitHub.Message.GitHubEventsMsg (Ok response)) ->
            let
                model2 =
                    updateEventStream response model
            in
            ( model2
            , maybeReadEventsNextPage model response
            )

        GitHubResponseEvents (GitHub.Message.GitHubEventsMsg (Err error)) ->
            handleHttpError error model

        _ ->
            ( model, Cmd.none )


handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
handleHttpError error model =
    case error of
        Http.BadStatus status ->
            case status of
                304 ->
                    ( model, Cmd.batch [ delaySeconds model.limits.xPollInterval ReadEvents ] )

                _ ->
                    ( eventStreamErrorLens.set (Just error) model, Cmd.none )

        _ ->
            ( eventStreamErrorLens.set (Just error) model, Cmd.none )


updateEventStream : GitHubEventsChunk -> Model -> Model
updateEventStream response model =
    let
        queue =
            List.sortBy (.created_at >> posixToMillis >> negate) (model.eventStream.events ++ response.content)
    in
    { model
        | eventStream =
            model.eventStream
                |> eventsLens.set queue
                |> etagLens.set response.etag
                |> errorLens.set Nothing
    }
        |> limitsLens.set response.limits


maybeReadEventsNextPage : Model -> GitHubEventsChunk -> Cmd Msg
maybeReadEventsNextPage model response =
    let
        readEventsAfterDelay =
            delaySeconds model.limits.xPollInterval ReadEvents
    in
    if List.length model.eventStream.events >= model.preferences.maxNumberOfEventsInQueue then
        readEventsAfterDelay

    else
        Dict.get "next" response.links
            |> Maybe.andThen Url.fromString
            |> Maybe.map ReadEventsNextPage
            |> Maybe.map (delaySeconds 0)
            |> Maybe.withDefault readEventsAfterDelay


resetEventStreamIfSourceChanged : GitHubEventSource -> Model -> Model
resetEventStreamIfSourceChanged source model =
    if model.eventStream.source /= source then
        model
            |> eventStreamSourceLens.set source
            |> eventStreamEventsLens.set []
            |> timelineEventsLens.set []

    else
        model
