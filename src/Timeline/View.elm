module Timeline.View exposing (view)

import Http
import Time.DateTime as DateTime
import Html exposing (Html, text, div, img, span, section, main_, header)
import Html.Attributes exposing (..)
import Main.Message exposing (..)
import Main.Model exposing (EventStream)
import Github.Model exposing (..)


view : EventStream -> Html Msg
view eventStream =
    section [ class "mdl-layout mdl-js-layout" ]
        [ header [ class "mdl-layout__header" ]
            [ div [ class "mdl-layout__header-row" ]
                [ span [ class "mdl-layout__title" ]
                    [ text ("What's going on " ++ sourceTitle (eventStream.source)) ]
                ]
            ]
        , section [ class "timeline-error" ] [ viewError eventStream.error ]
        , main_ [ class "timeline mdl-layout__content" ] (List.map viewEvent eventStream.events)
        ]


viewEvent : GithubEvent -> Html Msg
viewEvent event =
    section
        [ classList [ ( "card-event mdl-card mdl-shadow--2dp", True ), ( "card-event-" ++ event.eventType, True ) ] ]
        [ div
            [ class "mdl-card__supporting-text mdl-card--expand"
            , style [ ( "background-image", "url('" ++ event.actor.avatar_url ++ "')" ) ]
            ]
            [ div [ class "card-event-datetime" ] (formatDate event.created_at)
            , div [ class "card-event-repo" ] [ text (String.dropLeft 5 event.repo.name) ]
            , div [ class "card-event-actor" ] [ text (event.actor.display_login) ]
            ]
        , div [ class "mdl-card__actions" ]
            [ span [ class "card-event-type" ] [ text (String.dropRight 5 event.eventType) ]
            ]
        ]


formatDate : DateTime.DateTime -> List (Html Msg)
formatDate date =
    [ span [ class "card-event-time" ]
        [ text
            (to2String (DateTime.hour date)
                ++ ":"
                ++ to2String (DateTime.minute date)
                ++ ":"
                ++ to2String (DateTime.second date)
            )
        ]
    , span [ class "card-event-date" ]
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
            " Github.com repos of " ++ user ++ "?"
