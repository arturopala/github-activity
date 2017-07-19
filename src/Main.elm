module Main exposing (..)

import Html exposing (Html, text, div, img, span)
import Html.Attributes exposing (..)
import Github exposing (getEvents)

import Message exposing (..)
import Model exposing (..)

import Http
import Time
import Task
import Process

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
    , getEvents )



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of 
        NewEvents (Ok events) -> ( Model events Nothing, Cmd.none )
        NewEvents (Err error) -> (Model [] (Just error), Cmd.none)
        NoOp -> (model, Cmd.none) 


---- VIEW ----


view : Model -> Html Msg
view model =
    div []
    [ div [class "header"] [text "What's going today on HMRC Digital?"]
    , div [class "error"] [viewError model.error]
    , div [class "event-list"] (List.map viewEvent model.events)
    ]

viewEvent: GithubEvent -> Html Msg
viewEvent event =
    div [classList [("event-item",True), ("event-"++event.eventType,True)]]
        [ img [src event.actor.avatar_url, class "event-avatar"][] 
        , span [class "event-actor"][text (event.actor.display_login)]
        , span [class "event-repo"][text (String.dropLeft 5 event.repo.name)]
        , span [class "event-date"][text event.created_at]
        , span [class "event-type"][text event.eventType]
        ] 

viewError: Maybe Http.Error -> Html Msg
viewError error = 
    case error of
        Nothing -> text ""
        Just (Http.BadUrl str) -> text ("Bad URL " ++ str)
        Just Http.Timeout -> text "Timeout"
        Just (Http.NetworkError) -> text "Network error"
        Just (Http.BadStatus response) -> text ("Bad status " ++ (toString response.status.code))
        Just (Http.BadPayload debug response) -> text ("Bad payload " ++ debug)
