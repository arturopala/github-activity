module Timeline.View exposing (view)

import DateFormat
import GitHub.Authorization exposing (Authorization(..))
import GitHub.Model exposing (..)
import Html exposing (Html, button, div, header, i, main_, nav, section, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed exposing (node)
import Http
import Markdown
import Message exposing (Msg(..))
import Model exposing (Model)
import Time exposing (..)
import Timeline.Message
import Util exposing (push)
import View


view : Model -> Html Msg
view model =
    section [ class "mdl-layout mdl-layout--fixed-header timeline" ]
        [ viewHeader model
        , viewContent model
        ]


viewHeader : Model -> Html Msg
viewHeader model =
    if model.fullscreen then
        span [] []

    else
        header [ class "mdl-layout__header" ]
            [ div [ class "mdl-layout-icon" ]
                [ i [ classList [ ( "mdi", True ), ( "mdi-github-circle", True ), ( "mdi-spin", model.downloading ) ] ] [] ]
            , div [ class "mdl-layout__header-row" ]
                ([ span [ class "mdl-layout__title" ]
                    [ text "GitHub Activity"
                    , span [ class "title-source" ] [ text (" of " ++ View.sourceLabel model.eventStream.source) ]
                    ]
                 , div [ class "mdl-layout-spacer" ] []
                 ]
                    ++ navigation model
                )
            ]


viewContent : Model -> Html Msg
viewContent model =
    main_
        [ class "mdl-layout__content" ]
        [ node "div"
            [ classList [ ( "page-content", True ), ( "waiting-for-content", List.isEmpty model.timeline.events ) ] ]
            (case model.timeline.events of
                [] ->
                    case model.eventStream.error of
                        Just error ->
                            viewError error

                        Nothing ->
                            if model.downloading then
                                viewSpinner model

                            else
                                viewEmpty model

                events ->
                    viewEvents model.zone events
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
            viewIssuesEvent zone event payload

        GitHubIssueCommentEvent payload ->
            viewIssueCommentEvent zone event payload

        GitHubCreateEvent payload ->
            viewCreateEvent zone event payload

        GitHubDeleteEvent payload ->
            viewDeleteEvent zone event payload

        GitHubForkEvent payload ->
            viewForkEvent zone event payload

        GitHubWatchEvent ->
            viewWatchEvent zone event

        _ ->
            let
                label =
                    case event.eventType of
                        "CommitCommentEvent" ->
                            "Commit Comment"

                        _ ->
                            String.dropRight 5 event.eventType

                subtype =
                    ""
            in
            viewEventTemplate zone event [] label subtype
    )


viewEventTemplate : Zone -> GitHubEvent -> List (Html Msg) -> String -> String -> Html Msg
viewEventTemplate zone event content label subtype =
    section
        [ classList
            [ ( "card-event mdl-card mdl-shadow--2dp", True )
            , ( "events-group-" ++ eventGroupName event, True )
            , ( "events-" ++ eventTypeName event, True )
            , ( "event-"
                    ++ eventTypeName event
                    ++ (if String.isEmpty subtype then
                            ""

                        else
                            "-" ++ subtype
                       )
              , True
              )
            ]
        ]
        [ div
            [ class "mdl-card__supporting-text mdl-card--expand"
            , style "background-image" ("url('" ++ event.actor.avatar_url ++ "')")
            ]
            [ div [ class "card-event-actor" ] [ text event.actor.display_login ]
            , div [ class "card-event-datetime" ] (formatDate zone event.created_at)
            , div [ class "card-event-repo" ] [ text (String.replace "/" " / " event.repo.name) ]
            , div [ class "card-event-content" ] content
            ]
        , div [ class "mdl-card__actions card-event-label" ]
            [ span [ class "card-event-type" ] [ text (String.toLower label) ]
            ]
        ]


viewEventTemplateNoLabel : Zone -> GitHubEvent -> List (Html Msg) -> String -> Html Msg
viewEventTemplateNoLabel zone event content subtype =
    section
        [ classList
            [ ( "card-event mdl-card mdl-shadow--2dp", True )
            , ( "events-group-" ++ eventGroupName event, True )
            , ( "events-" ++ eventTypeName event, True )
            , ( "event-"
                    ++ eventTypeName event
                    ++ (if String.isEmpty subtype then
                            ""

                        else
                            "-" ++ subtype
                       )
              , True
              )
            ]
        ]
        [ div
            [ class "mdl-card__supporting-text mdl-card--expand"
            , style "background-image" ("url('" ++ event.actor.avatar_url ++ "')")
            ]
            [ div [ class "card-event-actor" ] [ text event.actor.display_login ]
            , div [ class "card-event-datetime" ] (formatDate zone event.created_at)
            , div [ class "card-event-repo" ] [ text (String.replace "/" " / " event.repo.name) ]
            , div [ class "card-event-content" ] content
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

        subtype =
            case payload.action of
                "closed" ->
                    if payload.pull_request.merged then
                        "merged"

                    else
                        "rejected"

                _ ->
                    payload.action

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
    viewEventTemplate zone event content label subtype


viewPullRequestReviewEvent : Zone -> GitHubEvent -> GitHubPullRequestReviewEventPayload -> Html Msg
viewPullRequestReviewEvent zone event payload =
    let
        label =
            "review of #"
                ++ String.fromInt payload.pull_request.number
                ++ " "
                ++ payload.action

        subtype =
            payload.action

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
    viewEventTemplate zone event content label subtype


viewPullRequestReviewCommentEvent : Zone -> GitHubEvent -> GitHubPullRequestReviewCommentEventPayload -> Html Msg
viewPullRequestReviewCommentEvent zone event payload =
    let
        label =
            case payload.action of
                "created" ->
                    "#" ++ String.fromInt payload.pull_request.number ++ " commented"

                _ ->
                    "review comment " ++ payload.action

        subtype =
            payload.action

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
                            [ Markdown.toHtmlWith markdownOptions [ class "cb-msg" ] msg
                            ]
                        )
                    |> Maybe.withDefault []
                )
            ]
    in
    viewEventTemplate zone event content label subtype


viewReleaseEvent : Zone -> GitHubEvent -> GitHubReleaseEventPayload -> Html Msg
viewReleaseEvent zone event payload =
    let
        label =
            "release " ++ payload.action

        subtype =
            payload.action

        content =
            [ div [ class "card-event-content-body card-event-content-body__center" ]
                [ div [ class "cb-big" ] [ text payload.release.tag_name ] ]
            ]
    in
    viewEventTemplate zone event content label subtype


viewPushEvent : Zone -> GitHubEvent -> GitHubPushEventPayload -> Html Msg
viewPushEvent zone event payload =
    let
        label =
            "push"

        subtype =
            ""

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
    viewEventTemplate zone event content label subtype


viewIssuesEvent : Zone -> GitHubEvent -> GitHubIssuesEventPayload -> Html Msg
viewIssuesEvent zone event payload =
    let
        label =
            (case payload.action of
                "opened" ->
                    "new "

                _ ->
                    ""
            )
                ++ "issue #"
                ++ String.fromInt payload.issue.number
                ++ (case payload.action of
                        "opened" ->
                            ""

                        _ ->
                            " " ++ payload.action
                   )

        subtype =
            payload.action

        content =
            [ div [ class "card-event-content-header" ]
                [ span [ class "ch-number" ]
                    ([ text "#"
                     , text (String.fromInt payload.issue.number)
                     ]
                        ++ (payload.issue.labels |> List.map (\l -> span [ class "ch-label spaced", style "background-color" ("#" ++ l.color) ] [ text (String.replace "itype:" "" l.name) ]))
                    )
                ]
            , div [ class "card-event-content-body" ]
                [ span [ class "cb-title" ]
                    [ text payload.issue.title
                    ]
                ]
            ]
    in
    viewEventTemplate zone event content label subtype


viewIssueCommentEvent : Zone -> GitHubEvent -> GitHubIssueCommentEventPayload -> Html Msg
viewIssueCommentEvent zone event payload =
    let
        label =
            case payload.action of
                "created" ->
                    "issue #" ++ String.fromInt payload.issue.number ++ " commented"

                _ ->
                    "issue comment " ++ payload.action

        subtype =
            payload.action

        content =
            [ div [ class "card-event-content-header" ]
                [ span [ class "ch-number" ]
                    ([ text "#"
                     , text (String.fromInt payload.issue.number)
                     ]
                        ++ (payload.issue.labels |> List.map (\l -> span [ class "ch-label spaced", style "background-color" ("#" ++ l.color) ] [ text (String.replace "itype:" "" l.name) ]))
                        ++ [ span [ class "issue-ref" ]
                                [ text payload.issue.title
                                ]
                           ]
                    )
                ]
            , div [ class "card-event-content-body" ]
                (payload.comment.body
                    |> Maybe.map
                        (\msg ->
                            [ Markdown.toHtmlWith markdownOptions [ class "cb-msg" ] msg
                            ]
                        )
                    |> Maybe.withDefault []
                )
            ]
    in
    viewEventTemplate zone event content label subtype


viewCreateEvent : Zone -> GitHubEvent -> GitHubCreateEventPayload -> Html Msg
viewCreateEvent zone event payload =
    let
        label =
            "create " ++ payload.ref_type

        subtype =
            payload.ref_type

        content =
            [ div [ class "card-event-content-body card-event-content-body__center" ]
                [ div [ class "cb-big" ] [ text payload.ref ] ]
            ]
    in
    viewEventTemplate zone event content label subtype


viewDeleteEvent : Zone -> GitHubEvent -> GitHubDeleteEventPayload -> Html Msg
viewDeleteEvent zone event payload =
    let
        label =
            "delete " ++ payload.ref_type

        subtype =
            payload.ref_type

        content =
            [ div [ class "card-event-content-body card-event-content-body__center" ]
                [ div [ class "cb-big" ] [ text payload.ref ] ]
            ]
    in
    viewEventTemplate zone event content label subtype


viewForkEvent : Zone -> GitHubEvent -> GitHubForkEventPayload -> Html Msg
viewForkEvent zone event payload =
    let
        label =
            "fork"

        subtype =
            ""

        content =
            [ div [ class "card-event-content-body card-event-content-body__center" ]
                [ div [ class "cb-big" ] [ text (payload.forkee.owner.login ++ " / " ++ payload.forkee.name) ] ]
            ]
    in
    viewEventTemplate zone event content label subtype


viewWatchEvent : Zone -> GitHubEvent -> Html Msg
viewWatchEvent zone event =
    let
        subtype =
            ""

        content =
            [ i [ class "material-icons" ] [ text "stars" ]
            ]
    in
    viewEventTemplateNoLabel zone event content subtype


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
                Token _ _ ->
                    pauseResumeButton model
                        ++ [ button
                                [ onClick (NavigateCommand Nothing Nothing)
                                , class "mdl-button mdl-button--colored mdl-color-text--white"
                                ]
                                [ span [ class "button-text" ] [ text "Source" ]
                                , i [ class "mdi mdi-power-plug" ] []
                                ]
                           , button
                                [ onClick SignOutCommand
                                , class "mdl-button mdl-button--colored mdl-color-text--white"
                                ]
                                [ span [ class "button-text" ] [ text "Sign out" ]
                                , i [ class "mdi mdi-logout" ] []
                                ]
                           ]

                Unauthorized ->
                    [ button
                        [ onClick (AuthorizeUserCommand (push (ChangeEventSourceCommand model.eventStream.source)))
                        , class "mdl-button mdl-button--colored mdl-color-text--white"
                        ]
                        [ span [ class "button-text" ] [ text "Sign in" ]
                        , i [ class "mdi mdi-github-circle" ] []
                        ]
                    ]
    in
    [ nav
        [ class "mdl-navigation" ]
        elements
    ]


pauseResumeButton : Model -> List (Html Msg)
pauseResumeButton model =
    if model.timeline.active then
        [ button
            [ onClick (TimelineMsg Timeline.Message.PauseCommand)
            , class "mdl-button mdl-button--colored mdl-color-text--white"
            ]
            [ span [ class "button-text" ] [ text "Pause" ]
            , i [ class "mdi mdi-pause" ] []
            ]
        ]

    else
        [ button
            [ onClick (TimelineMsg Timeline.Message.PlayCommand)
            , class "mdl-button mdl-button--colored mdl-color-text--white"
            ]
            [ span [ class "button-text" ] [ text "Play" ]
            , i [ class "mdi mdi-play" ] []
            ]
        ]


viewSpinner : Model -> List ( String, Html Msg )
viewSpinner model =
    [ ( "spinner"
      , span []
            [ i
                [ class "animated bounceInDown slower mdi mdi-cloud-download" ]
                []
            , span [] [ text "loading ..." ]
            ]
      )
    ]


viewEmpty : Model -> List ( String, Html Msg )
viewEmpty model =
    [ ( "empty"
      , span []
            [ i
                [ class "animated fadeIn slower mdi mdi-package-variant" ]
                []
            , span [] [ text "no events" ]
            ]
      )
    ]


viewError : Http.Error -> List ( String, Html Msg )
viewError error =
    case error of
        Http.NetworkError ->
            [ ( "network-error"
              , span []
                    [ i
                        [ class "animated rotateIn slower mdi mdi-cloud-off-outline" ]
                        []
                    , span [] [ text "no network" ]
                    ]
              )
            ]

        Http.Timeout ->
            [ ( "network-timeout"
              , span []
                    [ i
                        [ class "animated rotateIn slower mdi mdi-cloud-alert" ]
                        []
                    , span []
                        [ text "network timeout"
                        , button [ class "mdl-button mdl-button--colored mdl-color-text--white" ]
                            [ span [ class "button-text" ] [ text "Retry" ] ]
                        ]
                    ]
              )
            ]

        Http.BadStatus status ->
            [ ( "bad-status" ++ String.fromInt status
              , span []
                    [ i
                        [ class "animated rotateIn slower mdi mdi-cloud-question" ]
                        []
                    , span [] [ text (String.fromInt status) ]
                    ]
              )
            ]

        _ ->
            [ ( "other-error"
              , span []
                    [ i
                        [ class "animated rotateIn slower mdi mdi-cloud-question" ]
                        []
                    , span [] [ text "errors" ]
                    ]
              )
            ]


eventTypeName : GitHubEvent -> String
eventTypeName event =
    case event.payload of
        GitHubPullRequestEvent _ ->
            "pull-request"

        GitHubPullRequestReviewEvent _ ->
            "pull-request-review"

        GitHubPullRequestReviewCommentEvent _ ->
            "pull-request-review-comment"

        GitHubReleaseEvent _ ->
            "release"

        GitHubPushEvent _ ->
            "push"

        GitHubIssuesEvent _ ->
            "issues"

        GitHubIssueCommentEvent _ ->
            "issue-comment"

        _ ->
            String.replace " " "-" (String.dropRight 5 event.eventType) |> String.toLower


eventGroupName : GitHubEvent -> String
eventGroupName event =
    case event.payload of
        GitHubPullRequestEvent _ ->
            "pull-request"

        GitHubPullRequestReviewEvent _ ->
            "pull-request"

        GitHubPullRequestReviewCommentEvent _ ->
            "pull-request"

        GitHubReleaseEvent _ ->
            "release"

        GitHubPushEvent _ ->
            "push"

        GitHubIssuesEvent _ ->
            "issue"

        GitHubIssueCommentEvent _ ->
            "issue"

        _ ->
            "other"


markdownOptions : Markdown.Options
markdownOptions =
    let
        options =
            Markdown.defaultOptions
    in
    { options | smartypants = True }
