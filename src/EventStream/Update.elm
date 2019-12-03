module EventStream.Update exposing (resetEventStreamIfSourceChanged, update)

import Basics as Math
import Dict exposing (Dict)
import EventStream.Message
import EventStream.Model exposing (chunksLens)
import GitHub.API3Request exposing (readGitHubEvents, readGitHubEventsNextPage)
import GitHub.Authorization exposing (Authorization)
import GitHub.Model exposing (GitHubApiLimits, GitHubEvent, GitHubEventSource(..), GitHubSuccess)
import Message exposing (Msg(..))
import Model exposing (Model, downloadingLens, eventStreamChunksLens, eventStreamErrorLens, eventStreamEventsLens, eventStreamSourceLens, timelineEventsLens)
import Time exposing (posixToMillis)
import Url
import Util exposing (..)


update : Msg -> Authorization -> Model -> ( Model, Cmd Msg )
update msg auth model =
    case msg of
        EventStreamMsg msg2 ->
            case msg2 of
                EventStream.Message.ReadEvents ->
                    let
                        etag =
                            model
                                |> Util.getFromDict Model.etagsLens (GitHub.Model.sourceToString model.eventStream.source)
                                |> Maybe.withDefault ""

                        ( model2, cmd ) =
                            if model.timeline.active then
                                ( model
                                    |> downloadingLens.set True
                                , readGitHubEvents model.eventStream.source etag auth
                                    |> Cmd.map GitHubMsg
                                )

                            else
                                ( model, scheduleNextRead model )
                    in
                    ( model2, Cmd.batch [ cmd, delayMessage 5 (EventStreamMsg <| EventStream.Message.ForceFlushChunksAfterTimeout) ] )

                EventStream.Message.ReadEventsNextPage source url ->
                    let
                        shouldRead =
                            source == model.eventStream.source
                    in
                    ( model
                        |> downloadingLens.set shouldRead
                    , if shouldRead then
                        readGitHubEventsNextPage source url "" auth
                            |> Cmd.map GitHubMsg

                      else
                        Cmd.none
                    )

                EventStream.Message.GotEvents source etag links events ->
                    let
                        model2 =
                            updateChunks events model
                                |> eventStreamErrorLens.set Nothing
                    in
                    maybeReadEventsNextPage model2 links

                EventStream.Message.GotEventsNextPage source _ links page events ->
                    let
                        model2 =
                            updateChunks events model
                                |> eventStreamErrorLens.set Nothing
                    in
                    maybeReadEventsNextPage model2 links

                EventStream.Message.NothingNew ->
                    ( model
                        |> eventStreamErrorLens.set Nothing
                        |> downloadingLens.set False
                    , scheduleNextRead model
                    )

                EventStream.Message.TemporaryFailure error ->
                    ( model
                        |> eventStreamErrorLens.set (Just error)
                        |> downloadingLens.set False
                    , scheduleNextRead model
                    )

                EventStream.Message.PermanentFailure error ->
                    ( model
                        |> eventStreamErrorLens.set (Just error)
                        |> downloadingLens.set False
                    , Cmd.none
                    )

                EventStream.Message.ForceFlushChunksAfterTimeout ->
                    let
                        model2 =
                            flushChunksToEvents model
                    in
                    ( model2, Cmd.none )

        _ ->
            ( model, Cmd.none )


updateChunks : List GitHubEvent -> Model -> Model
updateChunks events model =
    let
        chunks =
            model.eventStream.chunks ++ events
    in
    { model
        | eventStream =
            model.eventStream
                |> chunksLens.set chunks
    }


maybeReadEventsNextPage : Model -> Dict String String -> ( Model, Cmd Msg )
maybeReadEventsNextPage model links =
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
        Dict.get "next" links
            |> Maybe.andThen Url.fromString
            |> Maybe.map (EventStreamMsg << EventStream.Message.ReadEventsNextPage model.eventStream.source)
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
            |> timelineEventsLens.set []

    else
        model


scheduleNextRead : Model -> Cmd Msg
scheduleNextRead model =
    delayMessageBasedOnApiLimits model.limits model.limits.xPollInterval (EventStreamMsg <| EventStream.Message.ReadEvents)
