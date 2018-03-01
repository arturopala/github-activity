module Main exposing (..)

import Html exposing (Html, text, div, img, span, section)
import Html.Attributes exposing (..)
import Github exposing (getEvents)
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
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }



---- MODEL ----


init : ( Model, Cmd Msg )
init =
    ( Model [] Nothing
    , getEvents "/users/hmrc/events"
    )



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewEvents (Ok events) ->
            ( Model events Nothing, Cmd.none )

        NewEvents (Err error) ->
            ( Model [] (Just error), Cmd.none )

        NoOp ->
            ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    section [ class "app" ]
        [ section [ class "header" ] [ text "What's going on HMRC Digital?" ]
        , section [ class "error" ] [ viewError model.error ]
        , section [ class "event-list" ] (List.map viewEvent model.events)
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
