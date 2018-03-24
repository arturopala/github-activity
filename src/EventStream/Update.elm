module EventStream.Update exposing (init, update, route)

import Http
import Dict
import Util exposing (..)
import Navigation exposing (modifyUrl)
import Routing exposing (Route(..))
import EventStream.Message exposing (..)
import EventStream.Model exposing (..)
import Github.APIv3 exposing (readGithubEvents, readGithubEventsNextPage)
import Github.Model exposing (GithubEventSource(..), GithubEventsResponse)
import Github.Message


init : Route -> ( Model, Cmd Msg)
init route =
    let
        source =
            case route of
                EventsRoute source ->
                    source

                _ ->
                    defaultEventSource
    in
        { source = source
          , events = []
          , interval = 60
          , etag = ""
          , error = Nothing
        }
        ! [ modifyUrl (Routing.eventsSourceUrl source) ]


route : Route -> Model -> ( Model, Cmd Msg )
route route eventStream =
    case route of
        EventsRoute source ->
            { eventStream
                | source = source
                  , events = []
                  , interval = eventStream.interval
                  , etag = ""
                  , error = Nothing
            }
                ! [ delaySeconds 0 ReadEvents ]

        _ ->
            ( eventStream, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg eventStream =
    case msg of
        ReadEvents ->
            eventStream
                ! [ readGithubEvents eventStream.source eventStream.etag
                        |> Cmd.map GithubResponseEvents
                  ]

        GithubResponseEvents (Github.Message.GotEvents (Ok response)) ->
            setResponse response eventStream
                ! [ delaySeconds response.interval ReadEvents
                  , readEventsNextPage response
                  ]

        GithubResponseEvents (Github.Message.GotEvents (Err error)) ->
            handleHttpError error eventStream

        ReadEventsNextPage url ->
            eventStream
                ! [ readGithubEventsNextPage url
                        |> Cmd.map GithubResponseEventsNextPage
                  ]

        GithubResponseEventsNextPage (Github.Message.GotEvents (Ok response)) ->
            (eventStream
                |> eventsLens.set (eventStream.events ++ response.events))
                ! [ readEventsNextPage response ]

        GithubResponseEventsNextPage (Github.Message.GotEvents (Err error)) ->
            errorLens.set (Just error) eventStream ! [ Cmd.none ]

        NoOp ->
            eventStream ! [ Cmd.none ]


handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
handleHttpError error eventStream =
        case error of
            Http.BadStatus httpResponse ->
                case httpResponse.status.code of
                    304 ->
                        eventStream ! [ delaySeconds eventStream.interval ReadEvents ]

                    404 ->
                        errorLens.set (Just error) eventStream ! [ Cmd.none ]

                    _ ->
                        errorLens.set (Just error) eventStream ! [ Cmd.none ]

            _ ->
                errorLens.set (Just error) eventStream ! [ Cmd.none ]


setResponse : GithubEventsResponse -> Model -> Model
setResponse response eventStream =
    eventStream
        |> eventsLens.set (eventStream.events ++ response.events)
        |> intervalLens.set response.interval
        |> etagLens.set response.etag
        |> errorLens.set Nothing


readEventsNextPage : GithubEventsResponse -> Cmd Msg
readEventsNextPage response =
    Dict.get "next" response.links
        |> Maybe.map ReadEventsNextPage
        |> Maybe.withDefault NoOp
        |> delaySeconds 0
