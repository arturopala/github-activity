module EventStream.Update exposing (update)

import Dict
import EventStream.Message exposing (..)
import EventStream.Model exposing (..)
import GitHub.APIv3 exposing (readGitHubEvents, readGitHubEventsNextPage)
import GitHub.Message
import GitHub.Model exposing (GitHubEventSource(..), GitHubEventsChunk)
import Http
import Url
import Util exposing (..)


update : Msg -> Maybe String -> Model -> ( Model, Cmd Msg )
update msg tokenOpt eventStream =
    case msg of
        ReadEvents ->
            ( eventStream
            , Cmd.batch
                [ readGitHubEvents eventStream.source eventStream.etag tokenOpt
                    |> Cmd.map GitHubResponseEvents
                ]
            )

        GitHubResponseEvents (GitHub.Message.GotEventsChunk (Ok response)) ->
            ( setResponse response eventStream
            , Cmd.batch
                [ delaySeconds response.interval ReadEvents
                , readEventsNextPage response
                ]
            )

        GitHubResponseEvents (GitHub.Message.GotEventsChunk (Err error)) ->
            handleHttpError error eventStream

        ReadEventsNextPage url ->
            ( eventStream
            , Cmd.batch
                [ readGitHubEventsNextPage url eventStream.etag tokenOpt
                    |> Cmd.map GitHubResponseEventsNextPage
                ]
            )

        GitHubResponseEventsNextPage (GitHub.Message.GotEventsChunk (Ok response)) ->
            ( eventStream
                |> eventsLens.set (eventStream.events ++ response.events)
            , Cmd.batch [ readEventsNextPage response ]
            )

        GitHubResponseEventsNextPage (GitHub.Message.GotEventsChunk (Err error)) ->
            ( errorLens.set (Just error) eventStream, Cmd.none )

        _ ->
            ( eventStream, Cmd.none )


handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
handleHttpError error eventStream =
    case error of
        Http.BadStatus status ->
            case status of
                304 ->
                    ( eventStream, Cmd.batch [ delaySeconds eventStream.interval ReadEvents ] )

                404 ->
                    ( errorLens.set (Just error) eventStream, Cmd.none )

                _ ->
                    ( errorLens.set (Just error) eventStream, Cmd.none )

        _ ->
            ( errorLens.set (Just error) eventStream, Cmd.none )


setResponse : GitHubEventsChunk -> Model -> Model
setResponse response eventStream =
    eventStream
        |> eventsLens.set (eventStream.events ++ response.events)
        |> intervalLens.set response.interval
        |> etagLens.set response.etag
        |> errorLens.set Nothing


readEventsNextPage : GitHubEventsChunk -> Cmd Msg
readEventsNextPage response =
    Dict.get "next" response.links
        |> Maybe.andThen Url.fromString
        |> Maybe.map ReadEventsNextPage
        |> Maybe.withDefault NoOp
        |> delaySeconds 0
