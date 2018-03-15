module Main.Update exposing (update)

import Navigation exposing (Location, modifyUrl)
import Routing
import Http
import Time
import Task
import Process
import Main.Message exposing (..)
import Main.Model exposing (..)
import Github.APIv3 exposing (readGithubEvents)
import Github.Model exposing (GithubEventSource(..), GithubEventsResponse)
import Github.Message


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnLocationChange location ->
            handleLocationChange (Routing.parseLocation location) model

        ReadEvents ->
            model
                ! [ readGithubEvents model.eventStream.source model.eventStream.etag
                        |> Cmd.map GithubResponse
                  ]

        GithubResponse (Github.Message.GotEvents (Ok response)) ->
            setEventStream response model ! [ delaySeconds response.interval ReadEvents ]

        GithubResponse (Github.Message.GotEvents (Err error)) ->
            handleHttpError error model

        NoOp ->
            model ! [ Cmd.none ]


handleLocationChange : Route -> Model -> ( Model, Cmd Msg )
handleLocationChange route model =
    let
        es =
            model.eventStream
    in
        case route of
            EventsRoute source ->
                { model
                    | route = route
                    , eventStream =
                        { source = source
                        , events = []
                        , interval = es.interval
                        , etag = ""
                        , error = Nothing
                        }
                }
                    ! [ delaySeconds 0 ReadEvents ]

            NotFoundRoute ->
                model ! [ modifyUrl (Routing.eventsSourceUrl (GithubUser defaultUser)) ]


handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
handleHttpError error model =
    let
        es =
            model.eventStream
    in
        case error of
            Http.BadStatus httpResponse ->
                case httpResponse.status.code of
                    304 ->
                        model ! [ delaySeconds model.eventStream.interval ReadEvents ]

                    404 ->
                        errorLens.set (Just error) model ! [ Cmd.none ]

                    _ ->
                        errorLens.set (Just error) model ! [ Cmd.none ]

            _ ->
                errorLens.set (Just error) model ! [ Cmd.none ]


delaySeconds : Int -> m -> Cmd m
delaySeconds interval msg =
    Process.sleep ((toFloat interval) * Time.second)
        |> Task.perform (\_ -> msg)


setEventStream : GithubEventsResponse -> Model -> Model
setEventStream response model =
    model
        |> eventsLens.set response.events
        |> intervalLens.set response.interval
        |> etagLens.set response.etag
        |> errorLens.set Nothing
