module EventStream.Update exposing (resetEventStreamIfSourceChanged, update)

import Basics as Math
import Dict
import EventStream.Message exposing (..)
import EventStream.Model exposing (errorLens, etagLens, eventsLens)
import GitHub.APIv3 exposing (readGitHubEvents, readGitHubEventsNextPage)
import GitHub.Message
import GitHub.Model exposing (GitHubApiLimits, GitHubEvent, GitHubEventSource(..), GitHubEventsChunk, GitHubResponse)
import Http
import List as Math
import Model exposing (Authorization, Model, eventStreamErrorLens, eventStreamEtagLens, eventStreamEventsLens, eventStreamSourceLens, limitsLens, timelineEventsLens)
import Time exposing (posixToMillis)
import Url
import Util exposing (..)


update : Msg -> Authorization -> Model -> ( Model, Cmd Msg )
update msg auth model =
    case msg of
        ReadEvents ->
            ( model
            , readGitHubEvents model.eventStream.source model.eventStream.etag auth
                |> Cmd.map GitHubResponseEvents
            )

        ReadEventsNextPage source url ->
            ( model
            , if source == model.eventStream.source then
                readGitHubEventsNextPage url "" auth
                    |> Cmd.map GitHubResponseEventsNextPage

              else
                Cmd.none
            )

        GitHubResponseEvents (GitHub.Message.GitHubEventsMsg (Ok response)) ->
            let
                model2 =
                    updateEventStream response model
            in
            ( { model2 | eventStream = model.eventStream |> etagLens.set response.etag }
            , maybeReadEventsNextPage model response
            )

        GitHubResponseEventsNextPage (GitHub.Message.GitHubEventsMsg (Ok response)) ->
            let
                model2 =
                    updateEventStream response model
            in
            ( model2
            , maybeReadEventsNextPage model response
            )

        GitHubResponseEvents (GitHub.Message.GitHubEventsMsg (Err ( error, limits ))) ->
            let
                model2 =
                    limits
                        |> Maybe.map (\l -> limitsLens.set l model)
                        |> Maybe.withDefault model
            in
            handleHttpError error model2

        _ ->
            ( model, Cmd.none )


handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
handleHttpError error model =
    case error of
        Http.BadStatus 304 ->
            ( model
            , delayMessageBasedOnApiLimits model.limits model.limits.xPollInterval ReadEvents
            )

        Http.BadStatus 403 ->
            ( eventStreamErrorLens.set (Just error) model
            , delayMessageBasedOnApiLimits model.limits model.limits.xPollInterval ReadEvents
            )

        _ ->
            ( eventStreamErrorLens.set (Just error) model
            , Cmd.none
            )


updateEventStream : GitHubEventsChunk -> Model -> Model
updateEventStream response model =
    let
        queue =
            List.sortBy (.created_at >> posixToMillis) (model.eventStream.events ++ response.content)
                |> (\list -> List.drop (List.length list - model.preferences.maxNumberOfEventsInQueue) list)
    in
    { model
        | eventStream =
            model.eventStream
                |> eventsLens.set queue
                |> errorLens.set Nothing
    }
        |> limitsLens.set response.limits


maybeReadEventsNextPage : Model -> GitHubEventsChunk -> Cmd Msg
maybeReadEventsNextPage model response =
    let
        readEventsAfterDelay =
            delayMessageBasedOnApiLimits model.limits model.limits.xPollInterval ReadEvents
    in
    if List.length model.eventStream.events >= model.preferences.maxNumberOfEventsInQueue then
        readEventsAfterDelay

    else
        Dict.get "next" response.links
            |> Maybe.andThen Url.fromString
            |> Maybe.map (ReadEventsNextPage model.eventStream.source)
            |> Maybe.map (delayMessageBasedOnApiLimits model.limits 0)
            |> Maybe.withDefault readEventsAfterDelay


delayMessageBasedOnApiLimits : GitHubApiLimits -> Int -> m -> Cmd m
delayMessageBasedOnApiLimits limits interval msg =
    msg
        |> (if limits.xRateRemaining < 1 then
                limits.xRateReset
                    |> Maybe.map delayMessageUntil
                    |> Maybe.withDefault (delayMessage (Math.max interval 60))

            else
                delayMessage interval
           )


resetEventStreamIfSourceChanged : GitHubEventSource -> Model -> Model
resetEventStreamIfSourceChanged source model =
    if model.eventStream.source /= source then
        model
            |> eventStreamSourceLens.set source
            |> eventStreamEventsLens.set []
            |> eventStreamEtagLens.set ""
            |> timelineEventsLens.set []

    else
        model
