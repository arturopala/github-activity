module Timeline.View exposing (view)

import DateFormat
import GitHub.Model exposing (..)
import Html exposing (Html, button, div, header, i, main_, nav, section, span, text)
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
    section [ class "mdl-layout mdl-layout--fixed-header timeline" ]
        [ header [ class "mdl-layout__header" ]
            [ div [ class "mdl-layout-icon" ]
                [ i [ classList [ ( "mdi", True ), ( "mdi-github-circle", True ), ( "mdi-spin", model.downloading ) ] ] [] ]
            , div [ class "mdl-layout__header-row" ]
                ([ span [ class "mdl-layout__title" ]
                    [ text "GitHub Activity" ]
                 , div [ class "mdl-layout-spacer" ] []
                 ]
                    ++ navigation model
                )
            ]
        , main_
            [ class "mdl-layout__content" ]
            [ node "div"
                [ classList [ ( "page-content", True ), ( "waiting-for-content", List.isEmpty model.timeline.events ) ] ]
                (case model.timeline.events of
                    [] ->
                        case model.eventStream.error of
                            Just error ->
                                viewError error

                            Nothing ->
                                viewSpinner model

                    events ->
                        viewEvents model.zone events
                )
            ]
        ]


viewSpinner : Model -> List ( String, Html Msg )
viewSpinner model =
    [ ( "spinner"
      , i
            [ class "animated bounceInDown slower mdi mdi-cloud-download" ]
            []
      )
    ]


viewEvents : Zone -> List GitHubEvent -> List ( String, Html Msg )
viewEvents zone events =
    List.map (viewEvent zone) events


viewEvent : Zone -> GitHubEvent -> ( String, Html Msg )
viewEvent zone event =
    ( event.id
    , case event.payload of
        GitHubPullRequestEvent payload ->
            viewPullRequestEvent zone event payload

        GitHubPullRequestReviewEvent payload ->
            viewPullRequestReviewEvent zone event payload

        GitHubPullRequestReviewCommentEvent payload ->
            viewPullRequestReviewCommentEvent zone event payload

        GitHubReleaseEvent payload ->
            viewReleaseEvent zone event payload

        GitHubPushEvent payload ->
            viewPushEvent zone event payload

        GitHubIssuesEvent payload ->
            viewIssueEvent zone event payload

        _ ->
            let
                label =
                    case event.eventType of
                        "PullRequestReviewCommentEvent" ->
                            "Review Comment"

                        "IssueCommentEvent" ->
                            "Issue Comment"

                        "CommitCommentEvent" ->
                            "Commit Comment"

                        _ ->
                            String.dropRight 5 event.eventType

                snake =
                    String.replace " " "-" label |> String.toLower
            in
            viewEventTemplate1 zone event [] label snake
    )


viewEventTemplate1 : Zone -> GitHubEvent -> List (Html Msg) -> String -> String -> Html Msg
viewEventTemplate1 zone event content label snake =
    section
        [ classList [ ( "card-event mdl-card mdl-shadow--2dp", True ), ( "event-" ++ snake, True ) ] ]
        [ div
            [ class "mdl-card__supporting-text mdl-card--expand"
            , style "background-image" ("url('" ++ event.actor.avatar_url ++ "')")
            ]
            [ div [ class "card-event-actor" ] [ text event.actor.display_login ]
            , div [ class "card-event-datetime" ] (formatDate zone event.created_at)
            , div [ class "card-event-repo" ] [ text (String.replace "/" " / " event.repo.name) ]
            , div [ class "card-event-content" ] content
            ]
        , div [ classList [ ( "mdl-card__actions", True ), ( "event-" ++ snake, True ) ] ]
            [ span [ class "card-event-type" ] [ text (String.toLower label) ]
            ]
        ]


viewPullRequestEvent : Zone -> GitHubEvent -> GitHubPullRequestEventPayload -> Html Msg
viewPullRequestEvent zone event payload =
    let
        base =
            payload.pull_request.base.ref

        head =
            payload.pull_request.head.ref

        label =
            (case payload.action of
                "opened" ->
                    "new "

                _ ->
                    ""
            )
                ++ "pull request "
                ++ (case payload.action of
                        "closed" ->
                            if payload.pull_request.merged then
                                "#"
                                    ++ String.fromInt payload.pull_request.number
                                    ++ " "
                                    ++ "merged"

                            else
                                "rejected"

                        "opened" ->
                            "#"
                                ++ String.fromInt payload.pull_request.number
                                ++ " "

                        _ ->
                            payload.action
                   )

        snake =
            "pull-request-"
                ++ (case payload.action of
                        "closed" ->
                            if payload.pull_request.merged then
                                "merged"

                            else
                                "rejected"

                        _ ->
                            payload.action
                   )

        content =
            [ div [ class "card-event-content-header" ]
                [ span [ class "ch-number" ] [ text "#", text (String.fromInt payload.pull_request.number) ]
                , span [ class "ch-commits", title "number of commits" ] [ i [ class "mdi mdi-source-commit spaced" ] [], text (String.fromInt payload.pull_request.commits) ]
                , span [ class "ch-files", title "number of files changed" ] [ i [ class "mdi mdi-file-code-outline spaced" ] [], text (String.fromInt payload.pull_request.changed_files) ]
                , span [ class "ch-added", title "number of additions" ] [ i [ class "mdi mdi-plus-box-outline spaced" ] [], text (String.fromInt payload.pull_request.additions) ]
                , span [ class "ch-deleted", title "number of deletions" ] [ i [ class "mdi mdi-minus-box-outline spaced" ] [], text (String.fromInt payload.pull_request.deletions) ]
                , span [ class "ch-refs", title ("merge from " ++ payload.pull_request.head.label ++ " into " ++ payload.pull_request.base.label) ]
                    (case payload.action of
                        "closed" ->
                            if payload.pull_request.merged then
                                [ i
                                    [ class "mdi mdi-arrow-collapse-right spaced" ]
                                    []
                                , span [ class "ch-refs-base" ] [ text (String.left 23 base) ]
                                ]

                            else
                                [ i
                                    [ class "mdi mdi-cancel spaced" ]
                                    []
                                , span [ class "ch-refs-head" ] [ text (String.left 23 head) ]
                                ]

                        _ ->
                            if head /= base then
                                [ span [ class "ch-refs-base" ] [ text (String.left 11 base) ]
                                , i [ class "mdi mdi-arrow-left spaced" ] []
                                , span [ class "ch-refs-head" ] [ text (String.left (23 - Basics.min (String.length base) 11) head) ]
                                ]

                            else
                                [ i
                                    [ class "mdi mdi-arrow-expand-right" ]
                                    []
                                , span [ class "ch-refs-head" ] [ text (String.left 23 head) ]
                                ]
                    )
                ]
            , div [ class "card-event-content-body" ]
                [ span [ class "cb-title" ]
                    [ text payload.pull_request.title
                    ]
                ]
            ]
    in
    viewEventTemplate1 zone event content label snake


viewPullRequestReviewEvent : Zone -> GitHubEvent -> GitHubPullRequestReviewEventPayload -> Html Msg
viewPullRequestReviewEvent zone event payload =
    let
        label =
            "Review of #"
                ++ String.fromInt payload.pull_request.number
                ++ " "
                ++ payload.action

        snake =
            "review-" ++ payload.action

        content =
            [ div [ class "card-event-content-header" ]
                [ span [ class "ch-number" ] [ text "#", text (String.fromInt payload.pull_request.number) ]
                ]
            , div [ class "card-event-content-body" ]
                [ span [ class "cb-title" ]
                    [ text payload.pull_request.title
                    ]
                ]
            ]
    in
    viewEventTemplate1 zone event content label snake


viewPullRequestReviewCommentEvent : Zone -> GitHubEvent -> GitHubPullRequestReviewCommentEventPayload -> Html Msg
viewPullRequestReviewCommentEvent zone event payload =
    let
        label =
            case payload.action of
                "created" ->
                    "pr #" ++ String.fromInt payload.pull_request.number ++ " commented"

                _ ->
                    "Review Comment " ++ payload.action

        snake =
            "review-comment-" ++ payload.action

        content =
            [ div [ class "card-event-content-header" ]
                [ span [ class "ch-number" ]
                    [ text "#"
                    , text (String.fromInt payload.pull_request.number)
                    , span [ class "pull-request-ref" ]
                        [ text payload.pull_request.title
                        ]
                    ]
                ]
            , div [ class "card-event-content-body" ]
                (payload.comment.body
                    |> Maybe.map
                        (\msg ->
                            [ span [ class "cb-msg" ] [ text msg ]
                            ]
                        )
                    |> Maybe.withDefault []
                )
            ]
    in
    viewEventTemplate1 zone event content label snake


viewReleaseEvent : Zone -> GitHubEvent -> GitHubReleaseEventPayload -> Html Msg
viewReleaseEvent zone event payload =
    let
        label =
            "release " ++ payload.action

        snake =
            "release-" ++ payload.action

        content =
            [ div [ class "card-event-content-body card-event-content-body__center" ]
                [ div [ class "cb-big" ] [ text payload.release.tag_name ] ]
            ]
    in
    viewEventTemplate1 zone event content label snake


viewPushEvent : Zone -> GitHubEvent -> GitHubPushEventPayload -> Html Msg
viewPushEvent zone event payload =
    let
        label =
            "push"

        snake =
            "push"

        content =
            [ div [ class "card-event-content-header" ]
                [ span [ class "ch-commits", title "number of commits" ] [ i [ class "mdi mdi-source-commit spaced" ] [], text (String.fromInt payload.distinct_size) ]
                , span [ class "ch-refs" ]
                    [ i [ class "mdi mdi-arrow-expand-right spaced" ] []
                    , span [ class "e-pr-b-head" ] [ text (String.replace "refs/heads/" "" payload.ref) ]
                    ]
                ]
            , div [ class "card-event-content-body" ]
                (List.filter (\c -> not << String.isEmpty <| c.message) payload.commits
                    |> List.map (\c -> div [ class "cb-msg" ] [ span [ class "commit-sha" ] [ text (String.left 6 c.sha), text ": " ], text c.message ])
                )
            ]
    in
    viewEventTemplate1 zone event content label snake


viewIssueEvent : Zone -> GitHubEvent -> GitHubIssuesEventPayload -> Html Msg
viewIssueEvent zone event payload =
    let
        label =
            "issue #" ++ String.fromInt payload.issue.number ++ " " ++ payload.action

        snake =
            "issue-" ++ payload.action

        content =
            [ div [ class "card-event-content-header" ]
                ([ span [ class "ch-number" ]
                    [ text "#"
                    , text (String.fromInt payload.issue.number)
                    ]
                 ]
                    ++ (payload.issue.labels |> List.map (\l -> span [ class "ch-label spaced", style "color" ("#" ++ l.color) ] [ text (String.replace "itype:" "" l.name) ]))
                )
            , div [ class "card-event-content-body" ]
                [ span [ class "cb-title" ]
                    [ text payload.issue.title
                    ]
                ]
            ]
    in
    viewEventTemplate1 zone event content label snake


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
            case model.authorization of
                Model.Token _ _ ->
                    pauseResumeButton model
                        ++ [ button
                                [ onClick (NavigateCommand (Just "") Nothing)
                                , class "mdl-button mdl-button--colored mdl-color-text--white"
                                ]
                                [ span [ class "button-text" ] [ text (sourceName model.eventStream.source) ]
                                , i [ class "mdi mdi-power-plug left-spaced" ] []
                                ]
                           , button
                                [ onClick SignOutCommand
                                , class "mdl-button mdl-button--colored mdl-color-text--white"
                                ]
                                [ span [ class "button-text" ] [ text "Sign out" ]
                                , i [ class "mdi mdi-logout left-spaced" ] []
                                ]
                           ]

                Model.Unauthorized ->
                    [ button
                        [ onClick (AuthorizeUserCommand (push (ChangeEventSourceCommand model.eventStream.source)))
                        , class "mdl-button mdl-button--colored mdl-color-text--white"
                        ]
                        [ span [ class "button-text" ] [ text "Sign in" ]
                        , i [ class "mdi mdi-github-circle left-spaced" ] []
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
            , i [ class "mdi mdi-pause left-spaced" ] []
            ]
        ]

    else
        [ button
            [ onClick (TimelineMsg Timeline.Message.PlayCommand)
            , class "mdl-button mdl-button--colored mdl-color-text--white"
            ]
            [ span [ class "button-text" ] [ text "Play" ]
            , i [ class "mdi mdi-play left-spaced" ] []
            ]
        ]


viewError : Http.Error -> List ( String, Html Msg )
viewError error =
    case error of
        Http.NetworkError ->
            [ ( "network-error"
              , i
                    [ class "animated rotateIn slower mdi mdi-cloud-off-outline" ]
                    []
              )
            ]

        Http.Timeout ->
            [ ( "network-timeout"
              , i
                    [ class "animated rotateIn slower mdi mdi-cloud-alert" ]
                    []
              )
            ]

        _ ->
            [ ( "other-error"
              , i
                    [ class "animated rotateIn slower mdi mdi-cloud-question" ]
                    []
              )
            ]
