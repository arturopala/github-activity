module EventStream.Update exposing (resetEventStreamIfSourceChanged, update)

import Basics as Math
import Dict
import EventStream.Message exposing (..)
import EventStream.Model exposing (chunksLens, errorLens)
import GitHub.APIv3 exposing (readGitHubEvents, readGitHubEventsNextPage)
import GitHub.Authorization exposing (Authorization)
import GitHub.Message
import GitHub.Model exposing (GitHubApiLimits, GitHubEvent, GitHubEventSource(..), GitHubEventsChunk, GitHubResponse)
import Http
import Model exposing (Model, downloadingLens, eventStreamChunksLens, eventStreamErrorLens, eventStreamEtagLens, eventStreamEventsLens, eventStreamSourceLens, limitsLens, timelineEventsLens)
import Ports
import Time exposing (posixToMillis)
import Url
import Util exposing (..)


update : Msg -> Authorization -> Model -> ( Model, Cmd Msg )
update msg auth model =
    case msg of
        ReadEvents ->
            let
                ( model2, cmd ) =
                    if model.timeline.active then
                        ( { model | downloading = True }
                        , readGitHubEvents model.eventStream.source model.eventStream.etag auth
                            |> Cmd.map GitHubResponseEvents
                        )

                    else
                        ( model, scheduleNextRead model )
            in
            ( model2, Cmd.batch [ cmd, delayMessage 5 ForceFlushChunksAfterTimeout ] )

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
                    updateChunks response model
                        |> eventStreamEtagLens.set response.etag
                        |> eventStreamErrorLens.set Nothing
            in
            maybeReadEventsNextPage model2 response

        GitHubResponseEventsNextPage (GitHub.Message.GitHubEventsMsg (Ok response)) ->
            let
                model2 =
                    updateChunks response model
                        |> eventStreamErrorLens.set Nothing
            in
            maybeReadEventsNextPage model2 response

        GitHubResponseEvents (GitHub.Message.GitHubEventsMsg (Err ( error, limits ))) ->
            let
                model2 =
                    limits
                        |> Maybe.map (\l -> limitsLens.set l model)
                        |> Maybe.withDefault model
            in
            handleHttpError error model2

        GitHubResponseEventsNextPage (GitHub.Message.GitHubEventsMsg (Err ( error, limits ))) ->
            let
                model2 =
                    limits
                        |> Maybe.map (\l -> limitsLens.set l model)
                        |> Maybe.withDefault model
            in
            handleHttpError error model2

        ForceFlushChunksAfterTimeout ->
            let
                model2 =
                    flushChunksToEvents model
            in
            ( model2, Cmd.none )

        _ ->
            ( model, scheduleNextRead model )


handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
handleHttpError error model =
    case error of
        Http.BadStatus 304 ->
            ( model
                |> downloadingLens.set False
                |> eventStreamErrorLens.set Nothing
            , scheduleNextRead model
            )

        Http.BadStatus 403 ->
            ( model
                |> eventStreamErrorLens.set (Just error)
                |> downloadingLens.set False
            , scheduleNextRead model
            )

        Http.BadBody string ->
            ( model
                |> eventStreamErrorLens.set (Just error)
                |> downloadingLens.set False
            , Cmd.batch [ Ports.logError string, scheduleNextRead model ]
            )

        Http.BadUrl url ->
            ( model
                |> eventStreamErrorLens.set (Just error)
                |> downloadingLens.set False
            , Cmd.batch [ Ports.logError ("Bad URL: " ++ url), scheduleNextRead model ]
            )

        Http.NetworkError ->
            ( model
                |> eventStreamErrorLens.set (Just error)
                |> downloadingLens.set False
            , delayMessage 5 ReadEvents
            )

        _ ->
            ( model
                |> eventStreamErrorLens.set (Just error)
                |> downloadingLens.set False
            , scheduleNextRead model
            )


updateChunks : GitHubEventsChunk -> Model -> Model
updateChunks response model =
    let
        chunks =
            model.eventStream.chunks ++ response.content
    in
    { model
        | eventStream =
            model.eventStream
                |> chunksLens.set chunks
                |> errorLens.set Nothing
    }
        |> limitsLens.set response.limits


maybeReadEventsNextPage : Model -> GitHubEventsChunk -> ( Model, Cmd Msg )
maybeReadEventsNextPage model response =
    let
        readEventsAfterDelay _ =
            let
                model2 =
                    flushChunksToEvents model
                        |> downloadingLens.set False
            in
            ( model2, scheduleNextRead model2 )
    in
    if List.length model.eventStream.events >= model.preferences.maxNumberOfEventsInQueue then
        readEventsAfterDelay ()

    else
        Dict.get "next" response.links
            |> Maybe.andThen Url.fromString
            |> Maybe.map (ReadEventsNextPage model.eventStream.source)
            |> Maybe.map (\url -> ( model, delayMessageBasedOnApiLimits model.limits 0 url ))
            |> Maybe.withDefault (readEventsAfterDelay ())


flushChunksToEvents : Model -> Model
flushChunksToEvents model =
    let
        events =
            List.sortBy (.created_at >> posixToMillis) (model.eventStream.chunks ++ model.eventStream.events)
                |> (\list -> List.drop (List.length list - model.preferences.maxNumberOfEventsInQueue) list)
    in
    model
        |> eventStreamEventsLens.set events
        |> eventStreamChunksLens.set []


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


scheduleNextRead : Model -> Cmd Msg
scheduleNextRead model =
    delayMessageBasedOnApiLimits model.limits model.limits.xPollInterval ReadEvents
