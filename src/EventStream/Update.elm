module EventStream.Update exposing (readFrom, update)

import Dict
import EventStream.Message exposing (..)
import EventStream.Model exposing (..)
import Github.APIv3 exposing (readGithubEvents, readGithubEventsNextPage)
import Github.Message
import Github.Model exposing (GithubContext, GithubEventSource(..), GithubEventsResponse)
import Http
import Util exposing (..)


readFrom : GithubEventSource -> Model -> ( Model, Cmd Msg )
readFrom source eventStream =
    ( { eventStream
        | source = source
        , events = []
        , interval = eventStream.interval
        , context = GithubContext "" Nothing
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
                [ readGithubEvents eventStream.source eventStream.context
                    |> Cmd.map GithubResponseEvents
                ]
            )

        GithubResponseEvents (Github.Message.GotEvents (Ok response)) ->
            ( setResponse response eventStream
            , Cmd.batch
                [ delaySeconds response.interval ReadEvents
                , readEventsNextPage response
                ]
            )

        GithubResponseEvents (Github.Message.GotEvents (Err error)) ->
            handleHttpError error eventStream

        ReadEventsNextPage url ->
            ( eventStream
            , Cmd.batch
                [ readGithubEventsNextPage url eventStream.context
                    |> Cmd.map GithubResponseEventsNextPage
                ]
            )

        GithubResponseEventsNextPage (Github.Message.GotEvents (Ok response)) ->
            ( eventStream
                |> eventsLens.set (eventStream.events ++ response.events)
            , Cmd.batch [ readEventsNextPage response ]
            )

        GithubResponseEventsNextPage (Github.Message.GotEvents (Err error)) ->
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


setResponse : GithubEventsResponse -> Model -> Model
setResponse response eventStream =
    eventStream
        |> eventsLens.set (eventStream.events ++ response.events)
        |> intervalLens.set response.interval
        |> contextEtagLens.set response.etag
        |> errorLens.set Nothing


readEventsNextPage : GithubEventsResponse -> Cmd Msg
readEventsNextPage response =
    Dict.get "next" response.links
        |> Maybe.map ReadEventsNextPage
        |> Maybe.withDefault NoOp
        |> delaySeconds 0
