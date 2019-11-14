module Timeline.View exposing (view)

import DateFormat
import GitHub.Model exposing (..)
import Html exposing (Html, a, button, div, header, i, main_, nav, section, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed exposing (node)
import Http
import Message exposing (Msg(..))
import Model exposing (Model)
import Time exposing (..)
import Timeline.Message
import Util exposing (push)


view : Model -> Html Msg
view model =
    section [ classList [ ( "mdl-layout", True ), ( "mdl-layout--fixed-header", True ) ] ]
        [ header [ class "mdl-layout__header" ]
            [ div [ class "mdl-layout__header-row" ]
                ([ span [ class "mdl-layout__title" ]
                    [ text "GitHub Activity Stream" ]
                 , div [ class "mdl-layout-spacer" ] []
                 ]
                    ++ navigation model
                )
            ]
        , main_
            [ class "mdl-layout__content" ]
            [ node "div"
                [ class "timeline page-content" ]
                (viewEvents model.zone model.timeline.events)
            ]
        ]


viewEvents : Zone -> List GitHubEvent -> List ( String, Html Msg )
viewEvents zone events =
    List.map (viewEvent zone) events


viewEvent : Zone -> GitHubEvent -> ( String, Html Msg )
viewEvent zone event =
    let
        label =
            eventLabel event

        snake =
            String.replace " " "-" label
    in
    ( event.id
    , section
        [ classList [ ( "card-event mdl-card mdl-shadow--2dp", True ), ( "event-" ++ snake, True ) ] ]
        [ div
            [ class "mdl-card__supporting-text mdl-card--expand"
            , style "background-image" ("url('" ++ event.actor.avatar_url ++ "')")
            ]
            [ div [ class "card-event-datetime" ] (formatDate zone event.created_at)
            , div [ class "card-event-repo" ] [ text (String.replace "/" " / " event.repo.name) ]
            , div [ class "card-event-content" ] (contentPreview event)
            , div [ class "card-event-actor" ] [ text event.actor.display_login ]
            ]
        , div [ classList [ ( "mdl-card__actions", True ), ( "event-" ++ snake, True ) ] ]
            [ span [ class "card-event-type" ] [ text label ]
            ]
        ]
    )


eventLabel : GitHubEvent -> String
eventLabel event =
    String.toLower <|
        case event.payload of
            GitHubPullRequestEvent payload ->
                "Pull Request "
                    ++ (case payload.action of
                            "closed" ->
                                if payload.pull_request.merged then
                                    "merged"

                                else
                                    "rejected"

                            _ ->
                                payload.action
                       )

            GitHubReleaseEvent payload ->
                "Release " ++ payload.action

            _ ->
                case event.eventType of
                    "PullRequestReviewCommentEvent" ->
                        "Review Comment"

                    "IssueCommentEvent" ->
                        "Issue Comment"

                    "CommitCommentEvent" ->
                        "Commit Comment"

                    _ ->
                        String.dropRight 5 event.eventType


contentPreview : GitHubEvent -> List (Html Msg)
contentPreview event =
    case event.payload of
        GitHubPullRequestEvent payload ->
            [ div [ class "e-pr" ]
                [ span [ class "e-pr__cf" ] [ i [ class "far fa-file-alt fa-sm sm-right-spaced" ] [], text ("" ++ String.fromInt payload.pull_request.changed_files) ]
                , span [ class "e-pr__ad" ] [ i [ class "far fa-plus-square fa-sm sm-spaced" ] [], text ("" ++ String.fromInt payload.pull_request.additions) ]
                , span [ class "e-pr__de" ] [ i [ class "far fa-minus-square fa-sm sm-spaced" ] [], text ("" ++ String.fromInt payload.pull_request.deletions) ]
                ]
            , text (String.left 100 payload.pull_request.title)
            ]

        GitHubReleaseEvent payload ->
            [ div [ class "e-rel" ]
                [ text payload.release.tag_name ]
            ]

        _ ->
            []


formatDate : Zone -> Posix -> List (Html Msg)
formatDate zone date =
    [ span [ class "card-event-time" ]
        [ text
            (to2String (Time.toHour zone date)
                ++ ":"
                ++ to2String (Time.toMinute zone date)
                ++ ":"
                ++ to2String (Time.toSecond zone date)
            )
        ]
    , span [ class "card-event-date" ]
        [ text
            (to2String (Time.toDay zone date)
                ++ "/"
                ++ toMonthNo (Time.toMonth zone date)
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
        GitHubEventSourceDefault ->
            "all users"

        GitHubEventSourceUser user ->
            user ++ " user"

        GitHubEventSourceOrganisation org ->
            org ++ " organisation"

        GitHubEventSourceRepository owner repo ->
            owner ++ "/" ++ repo ++ " repository"


modelStatusDebug : Model -> String
modelStatusDebug model =
    [ String.fromInt model.limits.xRateRemaining
    , model.limits.xRateReset |> Maybe.map (formatDateTime model.zone) |> Maybe.withDefault "-"
    , String.fromInt <| List.length model.eventStream.events
    , String.fromInt <| List.length model.timeline.events
    ]
        |> List.foldl (\a b -> b ++ " | " ++ a) ""


formatDateTime : Zone -> Posix -> String
formatDateTime zone =
    DateFormat.format
        [ DateFormat.yearNumber
        , DateFormat.text "-"
        , DateFormat.monthNumber
        , DateFormat.text "-"
        , DateFormat.dayOfMonthNumber
        , DateFormat.text " "
        , DateFormat.hourMilitaryFixed
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        , DateFormat.text ":"
        , DateFormat.secondFixed
        ]
        zone


navigation : Model -> List (Html Msg)
navigation model =
    let
        elements =
            case model.user of
                Just user ->
                    pauseResumeButton model
                        ++ [ button
                                [ onClick (NavigateCommand (Just "") Nothing)
                                , class "mdl-button mdl-button--colored mdl-color-text--white"
                                ]
                                [ span [ class "button-text" ] [ text (sourceName model.eventStream.source) ]
                                , i [ class "fas fa-plug fa-lg left-spaced" ] []
                                ]
                           , button
                                [ onClick SignOutCommand
                                , class "mdl-button mdl-button--colored mdl-color-text--white"
                                ]
                                [ span [ class "button-text" ] [ text "Sign out" ]
                                , i [ class "fas fa-sign-out-alt fa-lg left-spaced" ] []
                                ]
                           ]

                Nothing ->
                    [ button
                        [ onClick (AuthorizeUserCommand (push (ChangeEventSourceCommand model.eventStream.source)))
                        , class "mdl-button mdl-button--colored mdl-color-text--white"
                        ]
                        [ span [ class "button-text" ] [ text "Sign in" ]
                        , i [ class "fab fa-github fa-lg left-spaced" ] []
                        ]
                    ]
    in
    [ nav
        [ class "mdl-navigation" ]
        elements
    ]


sourceName : GitHubEventSource -> String
sourceName source =
    case source of
        GitHubEventSourceDefault ->
            "all github"

        GitHubEventSourceUser user ->
            "user: " ++ user

        GitHubEventSourceOrganisation org ->
            "org: " ++ org

        GitHubEventSourceRepository owner repo ->
            "repo: " ++ owner ++ "/" ++ repo


pauseResumeButton : Model -> List (Html Msg)
pauseResumeButton model =
    if model.timeline.active then
        [ button
            [ onClick (TimelineMsg Timeline.Message.PauseCommand)
            , class "mdl-button mdl-button--colored mdl-color-text--white"
            ]
            [ span [ class "button-text" ] [ text "Pause" ]
            , i [ class "fas fa-pause fa-lg left-spaced" ] []
            ]
        ]

    else
        [ button
            [ onClick (TimelineMsg Timeline.Message.PlayCommand)
            , class "mdl-button mdl-button--colored mdl-color-text--white"
            ]
            [ span [ class "button-text" ] [ text "Play" ]
            , i [ class "fas fa-play fa-lg left-spaced" ] []
            ]
        ]
