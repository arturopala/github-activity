module EventStream.Update exposing (update)

import Dict
import EventStream.Message exposing (..)
import EventStream.Model exposing (..)
import GitHub.APIv3 exposing (readGitHubEvents, readGitHubEventsNextPage)
import GitHub.Message
import GitHub.Model exposing (GitHubEvent, GitHubEventSource(..), GitHubEventsChunk, GitHubResponse)
import Http
import Model exposing (Authorization)
import Url
import Util exposing (..)


update : Msg -> Authorization -> Model -> ( Model, Cmd Msg )
update msg tokenOpt eventStream =
    case msg of
        ReadEvents ->
            ( eventStream
            , Cmd.batch
                [ readGitHubEvents eventStream.source eventStream.etag tokenOpt
                    |> Cmd.map GitHubResponseEvents
                ]
            )

        ReadEventsNextPage url ->
            ( eventStream
            , Cmd.batch
                [ readGitHubEventsNextPage url eventStream.etag tokenOpt
                    |> Cmd.map GitHubResponseEventsNextPage
                ]
            )

        GitHubResponseEvents (GitHub.Message.GitHubEventsMsg (Ok response)) ->
            ( setResponse response eventStream
            , Cmd.batch
                [ delaySeconds response.interval ReadEvents
                , readEventsNextPage response
                ]
            )

        GitHubResponseEvents (GitHub.Message.GitHubEventsMsg (Err error)) ->
            handleHttpError error eventStream

        GitHubResponseEventsNextPage (GitHub.Message.GitHubEventsMsg (Ok response)) ->
            ( eventStream
                |> eventsLens.set (eventStream.events ++ response.content)
            , Cmd.batch [ readEventsNextPage response ]
            )

        GitHubResponseEventsNextPage (GitHub.Message.GitHubEventsMsg (Err error)) ->
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
        |> eventsLens.set (eventStream.events ++ response.content)
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
