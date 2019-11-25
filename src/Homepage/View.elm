module Homepage.View exposing (view)

import Components.UserSearch
import GitHub.Authorization exposing (Authorization(..))
import GitHub.Model
import Homepage.Message
import Html exposing (Html, button, div, h1, i, main_, section, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Lazy
import Message exposing (Msg)
import Model exposing (Model)
import Util
import View


view : Model -> Html Msg
view model =
    case model.authorization of
        Unauthorized ->
            Html.Lazy.lazy (showWelcome model) ()

        Token token scope ->
            Html.Lazy.lazy (showSelectSource model) model.user


showWelcome : Model -> () -> Html Msg
showWelcome model _ =
    section [ class "mdl-layout homepage" ]
        [ section [ class "mdl-layout__content" ]
            [ div [ class "card-login mdl-card mdl-shadow--2dp" ]
                [ div [ class "mdl-card__title mdl-typography--text-center mdl-color--white" ]
                    [ h1 [ class "mdl-color-text--primary" ]
                        [ span [ class "mdl-color-text--black" ] [ text "GitHub" ]
                        , text " Activity"
                        ]
                    ]
                , div [ class "mdl-card__actions mdl-card--border mdl-color--primary mdl-color-text--white" ]
                    [ button
                        [ onClick (Message.AuthorizeUserCommand Cmd.none)
                        , class "mdl-button mdl-button--colored mdl-color-text--white"
                        ]
                        [ text "Sign in with GitHub"
                        , i [ class "mdi mdi-github-circle float-right mdi-24px" ] []
                        ]
                    ]
                ]
            ]
        ]


showSelectSource : Model -> Maybe GitHub.Model.GitHubUser -> Html Msg
showSelectSource model maybeUser =
    let
        currentUserSourceList =
            case maybeUser of
                Just user ->
                    [ GitHub.Model.GitHubEventSourceUser user.login ]

                Nothing ->
                    []

        sources =
            List.reverse <|
                Util.mergeListsDistinct
                    (currentUserSourceList
                        ++ List.map (\o -> GitHub.Model.GitHubEventSourceOrganisation o.login) model.organisations
                        ++ [ GitHub.Model.GitHubEventSourceDefault ]
                    )
                    model.homepage.sourceHistory
    in
    section [ class "mdl-layout homepage" ]
        [ main_ [ class "mdl-layout__content" ]
            [ div [ class "card-login mdl-card mdl-shadow--2dp" ]
                ([ div [ class "mdl-card__title mdl-typography--text-center mdl-color--white" ]
                    [ h1 [ class "mdl-color-text--primary" ]
                        [ span [ class "mdl-color-text--black" ] [ text "GitHub" ]
                        , text " Activity"
                        ]
                    ]
                 , div [ class "mdl-card__actions mdl-color--secondary mdl-color-text--primary" ]
                    [ Components.UserSearch.view model.homepage.search
                        |> Html.map (Message.HomepageMsg << Homepage.Message.UserSearchMsg)
                    ]
                 , div
                    [ class "mdl-card__actions mdl-color--secondary mdl-color-text--primary search-result"
                    ]
                    (List.map showUserSearchResult (List.take 5 model.homepage.search.results))
                 , div [ class "mdl-card--expand" ] []
                 ]
                    ++ List.map (showSourceOption model) sources
                    ++ [ div [ class "mdl-card__actions mdl-card--border mdl-color--primary mdl-color-text--white" ]
                            [ button
                                [ onClick Message.SignOutCommand
                                , class "mdl-button mdl-button--colored mdl-color-text--white"
                                ]
                                [ text "Sign out"
                                , i [ class "mdi mdi-logout float-right  mdi-24px" ] []
                                ]
                            ]
                       ]
                )
            ]
        ]


showSourceOption : Model -> GitHub.Model.GitHubEventSource -> Html Msg
showSourceOption model source =
    let
        prefix =
            if source == model.eventStream.source then
                "Continue with "

            else
                "Stream "

        removable =
            source
                /= GitHub.Model.GitHubEventSourceDefault
                && source
                /= (model.user |> Maybe.map (\u -> GitHub.Model.GitHubEventSourceUser u.login) |> Maybe.withDefault GitHub.Model.GitHubEventSourceDefault)

        removeButton =
            if not removable then
                span [] []

            else
                button
                    [ class "mdl-button source-remove-button"
                    , onClick (Message.HomepageMsg <| Homepage.Message.RemoveSourceCommand source)
                    ]
                    [ i [ class "material-icons md-18" ] [ text "clear" ] ]
    in
    div [ class "mdl-card__actions mdl-card--border mdl-color--secondary mdl-color-text--primary" ]
        [ button
            [ onClick (Message.ChangeEventSourceCommand source)
            , classList
                [ ( "mdl-button", True )
                , ( "mdl-button--colored", True )
                , ( "mdl-color-text--primary", True )
                , ( "is-current-source", model.eventStream.source == source )
                ]
            ]
            [ text (prefix ++ View.sourceName source)
            ]
        , removeButton
        ]


showUserSearchResult : GitHub.Model.GitHubUserRef -> Html Msg
showUserSearchResult user =
    div [ onClick (Message.HomepageMsg <| Homepage.Message.SourceSelectedEvent (user |> toSource)) ]
        [ text user.login ]


toSource : GitHub.Model.GitHubUserRef -> GitHub.Model.GitHubEventSource
toSource user =
    case user.type_ of
        "Organization" ->
            GitHub.Model.GitHubEventSourceOrganisation user.login

        _ ->
            GitHub.Model.GitHubEventSourceUser user.login
