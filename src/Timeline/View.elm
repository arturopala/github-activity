module Timeline.View exposing (view)

import EventStream.Message exposing (..)
import EventStream.Model exposing (Model)
import GitHub.Model exposing (..)
import Html exposing (Html, div, header, main_, section, span, text)
import Html.Attributes exposing (..)
import Http
import Time exposing (..)


view : Model -> Html Msg
view eventStream =
    section [ class "mdl-layout mdl-js-layout" ]
        [ header [ class "mdl-layout__header" ]
            [ div [ class "mdl-layout__header-row" ]
                [ span [ class "mdl-layout__title" ]
                    [ text ("What's going on " ++ sourceTitle eventStream.source) ]
                ]
            ]
        , section [ class "timeline-error" ] [ viewError eventStream.error ]
        , main_ [ class "timeline mdl-layout__content" ] (List.map viewEvent eventStream.events)
        ]


viewEvent : GitHubEvent -> Html Msg
viewEvent event =
    section
        [ classList [ ( "card-event mdl-card mdl-shadow--2dp", True ), ( "card-event-" ++ event.eventType, True ) ] ]
        [ div
            [ class "mdl-card__supporting-text mdl-card--expand"
            , style "background-image" ("url('" ++ event.actor.avatar_url ++ "')")
            ]
            [ div [ class "card-event-datetime" ] (formatDate event.created_at)
            , div [ class "card-event-repo" ] [ text (String.dropLeft 5 event.repo.name) ]
            , div [ class "card-event-actor" ] [ text event.actor.display_login ]
            ]
        , div [ class "mdl-card__actions" ]
            [ span [ class "card-event-type" ] [ text (String.dropRight 5 event.eventType) ]
            ]
        ]


formatDate : Posix -> List (Html Msg)
formatDate date =
    [ span [ class "card-event-time" ]
        [ text
            (to2String (Time.toHour utc date)
                ++ ":"
                ++ to2String (Time.toMinute utc date)
                ++ ":"
                ++ to2String (Time.toSecond utc date)
            )
        ]
    , span [ class "card-event-date" ]
        [ text
            (to2String (Time.toDay utc date)
                ++ "/"
                ++ toMonthNo (Time.toMonth utc date)
            )
        ]
    ]


toMonthNo : Month -> String
toMonthNo month =
    case month of
        Jan ->
            "01"

        Feb ->
            "02"

        Mar ->
            "03"

        Apr ->
            "04"

        May ->
            "05"

        Jun ->
            "06"

        Jul ->
            "07"

        Aug ->
            "08"

        Sep ->
            "09"

        Oct ->
            "10"

        Nov ->
            "11"

        Dec ->
            "12"


to2String : Int -> String
to2String i =
    let
        s =
            String.fromInt i
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

        Just (Http.BadStatus status) ->
            text ("Bad status " ++ String.fromInt status)

        Just (Http.BadBody reason) ->
            text ("Bad payload " ++ reason)


sourceTitle : GitHubEventSource -> String
sourceTitle source =
    case source of
        None ->
            ""

        GitHubUser user ->
            " GitHub.com repos of " ++ user ++ "?"
