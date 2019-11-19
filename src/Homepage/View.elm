module Homepage.View exposing (view)

import GitHub.Model
import Homepage.Message
import Html exposing (Html, button, div, h1, i, input, label, main_, section, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Lazy
import Message exposing (..)
import Model exposing (Model)


view : Model -> Html Msg
view model =
    case model.user of
        Nothing ->
            Html.Lazy.lazy (showWelcome model) ()

        Just user ->
            Html.Lazy.lazy (showSelectSource model) user


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
                        [ onClick (AuthorizeUserCommand Cmd.none)
                        , class "mdl-button mdl-button--colored mdl-color-text--white"
                        ]
                        [ text "Sign in with GitHub"
                        , i [ class "mdi mdi-github-circle float-right mdi-24px" ] []
                        ]
                    ]
                ]
            ]
        ]


toSource : GitHub.Model.GitHubUserRef -> GitHub.Model.GitHubEventSource
toSource user =
    case user.type_ of
        "Organisation" ->
            GitHub.Model.GitHubEventSourceOrganisation user.login

        _ ->
            GitHub.Model.GitHubEventSourceUser user.login


showSelectSource : Model -> GitHub.Model.GitHubUser -> Html Msg
showSelectSource model user =
    let
        sources =
            appendIfDistinct
                model.eventStream.source
                ([ GitHub.Model.GitHubEventSourceUser user.login ]
                    ++ List.map (\o -> GitHub.Model.GitHubEventSourceOrganisation o.login) model.organisations
                    ++ [ GitHub.Model.GitHubEventSourceDefault ]
                )
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
                    [ div [ class "search-box mdl-color-text--primary" ]
                        [ div [ class "search-input-box" ]
                            [ i [ class "search-icon material-icons" ] [ text "search" ]
                            , input
                                [ class "search-input"
                                , type_ "text"
                                , pattern "[a-zA-Z0-9-]*"
                                , id "search"
                                , placeholder "Type to search for new streams"
                                , onInput (HomepageMsg << Homepage.Message.SearchCommand)
                                ]
                                []
                            ]
                        ]
                    ]
                 ]
                    ++ List.map showUserSearchResult (List.take 5 model.homepage.usersFound)
                    ++ List.map (showSourceOption model) sources
                    ++ [ div [ class "mdl-card--expand" ] []
                       , div [ class "mdl-card__actions mdl-card--border mdl-color--primary mdl-color-text--white" ]
                            [ button
                                [ onClick SignOutCommand
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
    div [ class "mdl-card__actions mdl-card--border mdl-color--secondary mdl-color-text--primary" ]
        [ button
            [ onClick (ChangeEventSourceCommand source)
            , classList
                [ ( "mdl-button", True )
                , ( "mdl-button--colored", True )
                , ( "mdl-color-text--primary", True )
                , ( "is-current-source", model.eventStream.source == source )
                ]
            ]
            [ sourceLabel source
            ]
        ]


sourceLabel : GitHub.Model.GitHubEventSource -> Html Msg
sourceLabel source =
    case source of
        GitHub.Model.GitHubEventSourceDefault ->
            text "Stream all public GitHub"

        GitHub.Model.GitHubEventSourceUser user ->
            text ("Stream user " ++ user)

        GitHub.Model.GitHubEventSourceOrganisation org ->
            text ("Stream org " ++ org)

        GitHub.Model.GitHubEventSourceRepository owner repo ->
            text ("Stream repo" ++ owner ++ "/" ++ repo)


showUserSearchResult : GitHub.Model.GitHubUserRef -> Html Msg
showUserSearchResult user =
    div [ class "mdl-card__actions mdl-color--secondary mdl-color-text--primary" ]
        [ span [ class "search-result" ] [ text user.login ]
        ]


appendIfDistinct : a -> List a -> List a
appendIfDistinct a list =
    case list of
        [] ->
            a :: []

        x :: xs ->
            if a == x then
                list

            else
                x :: appendIfDistinct a xs
