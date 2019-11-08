module EventStream.Update exposing (readFrom, update)

import Dict
import EventStream.Message exposing (..)
import EventStream.Model exposing (..)
import GitHub.APIv3 exposing (readGitHubEvents, readGitHubEventsNextPage)
import GitHub.Message
import GitHub.Model exposing (GitHubContext, GitHubEventSource(..), GitHubEventsResponse)
import Http
import Util exposing (..)


readFrom : GitHubEventSource -> Model -> ( Model, Cmd Msg )
readFrom source eventStream =
    ( { eventStream
        | source = source
        , events = []
        , interval = eventStream.interval
        , context = GitHubContext "" Nothing
        , error = Nothing
      }
    , Cmd.batch [ delaySeconds 0 ReadEvents ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg eventStream =
    case msg of
        ReadEvents ->
            ( eventStream
            , Cmd.batch
                [ readGitHubEvents eventStream.source eventStream.context
                    |> Cmd.map GitHubResponseEvents
                ]
            )

        GitHubResponseEvents (GitHub.Message.GotEvents (Ok response)) ->
            ( setResponse response eventStream
            , Cmd.batch
                [ delaySeconds response.interval ReadEvents
                , readEventsNextPage response
                ]
            )

        GitHubResponseEvents (GitHub.Message.GotEvents (Err error)) ->
            handleHttpError error eventStream

        ReadEventsNextPage url ->
            ( eventStream
            , Cmd.batch
                [ readGitHubEventsNextPage url eventStream.context
                    |> Cmd.map GitHubResponseEventsNextPage
                ]
            )

        GitHubResponseEventsNextPage (GitHub.Message.GotEvents (Ok response)) ->
            ( eventStream
                |> eventsLens.set (eventStream.events ++ response.events)
            , Cmd.batch [ readEventsNextPage response ]
            )

        GitHubResponseEventsNextPage (GitHub.Message.GotEvents (Err error)) ->
            ( errorLens.set (Just error) eventStream, Cmd.none )

        NoOp ->
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


setResponse : GitHubEventsResponse -> Model -> Model
setResponse response eventStream =
    eventStream
        |> eventsLens.set (eventStream.events ++ response.events)
        |> intervalLens.set response.interval
        |> contextEtagLens.set response.etag
        |> errorLens.set Nothing


readEventsNextPage : GitHubEventsResponse -> Cmd Msg
readEventsNextPage response =
    Dict.get "next" response.links
        |> Maybe.map ReadEventsNextPage
        |> Maybe.withDefault NoOp
        |> delaySeconds 0
