module Main exposing (..)

import Navigation exposing (Location, modifyUrl)
import Routing
import Html exposing (Html, text, div, img, span, section)
import Html.Attributes exposing (..)
import Github exposing (readGithubEvents)
import Message exposing (..)
import Model exposing (..)
import Http
import Time
import Task
import Process
import Time.DateTime as DateTime


---- PROGRAM ----


main : Program Never Model Msg
main =
    Navigation.program OnLocationChange
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



---- MODEL ----


defaultUser : String
defaultUser =
    "hmrc"


init : Location -> ( Model, Cmd Msg )
init location =
    let
        route =
            Routing.parseLocation location

        source =
            case route of
                EventsRoute source ->
                    source

                _ ->
                    GithubUser defaultUser
    in
        { route = route
        , eventStream =
            { source = source
            , events = []
            , interval = 60
            , etag = ""
            , error = Nothing
            }
        }
            ! [ modifyUrl (Routing.eventsSourceUrl source) ]



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnLocationChange location ->
            handleLocationChange (Routing.parseLocation location) model

        ReadEvents ->
            model ! [ readGithubEvents model.eventStream ]

        GotEvents (Ok response) ->
            let
                es =
                    model.eventStream
            in
                { model | eventStream = { es | events = response.events, interval = response.interval, etag = response.etag, error = Nothing } }
                    ! [ delaySeconds response.interval ReadEvents ]

        GotEvents (Err error) ->
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
                        { model | eventStream = { es | error = Just error } } ! [ Cmd.none ]

                    _ ->
                        { model | eventStream = { es | error = Just error } } ! [ Cmd.none ]

            _ ->
                { model | eventStream = { es | error = Just error } } ! [ Cmd.none ]


delaySeconds : Int -> m -> Cmd m
delaySeconds interval msg =
    Process.sleep ((toFloat interval) * Time.second)
        |> Task.perform (\_ -> msg)



---- VIEW ----


view : Model -> Html Msg
view model =
    section [ class "app" ]
        [ section [ class "header" ] [ text ("What's going on " ++ sourceTitle (model.eventStream.source)) ]
        , section [ class "error" ] [ viewError model.eventStream.error ]
        , section [ class "event-list" ] (List.map viewEvent model.eventStream.events)
        ]


viewEvent : GithubEvent -> Html Msg
viewEvent event =
    section [ classList [ ( "event-item", True ), ( "event-" ++ event.eventType, True ) ] ]
        [ img [ src event.actor.avatar_url, class "event-avatar" ] []
        , span [ class "event-datetime" ] (formatDate event.created_at)
        , span [ class "event-repo" ] [ text (String.dropLeft 5 event.repo.name) ]
        , span [ class "event-actor" ] [ text (event.actor.display_login) ]
        , span [ class "event-type" ] [ text (String.dropRight 5 event.eventType) ]
        ]


formatDate : DateTime.DateTime -> List (Html Msg)
formatDate date =
    [ span [ class "event-time" ]
        [ text
            (to2String (DateTime.hour date)
                ++ ":"
                ++ to2String (DateTime.minute date)
                ++ ":"
                ++ to2String (DateTime.second date)
            )
        ]
    , span [ class "event-date" ]
        [ text
            (to2String (DateTime.day date)
                ++ "/"
                ++ to2String (DateTime.month date)
            )
        ]
    ]


to2String : Int -> String
to2String i =
    let
        s =
            toString i
    in
        if String.length s == 1 then
            "0" ++ s
        else
            s


viewError : Maybe Http.Error -> Html Msg
viewError error =
    case error of
        Nothing ->
            text ""

        Just (Http.BadUrl str) ->
            text ("Bad URL " ++ str)

        Just Http.Timeout ->
            text "Timeout"

        Just Http.NetworkError ->
            text "Network error"

        Just (Http.BadStatus response) ->
            text ("Bad status " ++ (toString response.status.code))

        Just (Http.BadPayload debug response) ->
            text ("Bad payload " ++ debug)


sourceTitle : GithubEventSource -> String
sourceTitle source =
    case source of
        GithubUser user ->
            "user " ++ user
