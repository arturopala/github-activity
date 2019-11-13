module Homepage.View exposing (view)

import GitHub.Model
import Html exposing (Html, button, div, h1, i, main_, section, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
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
    section [ class "mdl-layout" ]
        [ section [ class "homepage mdl-layout__content" ]
            [ div [ class "card-login mdl-card mdl-shadow--2dp" ]
                [ div [ class "mdl-card__title mdl-card--expand mdl-typography--text-center mdl-color--white" ]
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
                        ]
                    , div [ class "mdl-layout-spacer" ] []
                    , i [ class "fab fa-github fa-lg" ] []
                    ]
                ]
            ]
        ]


showSelectSource : Model -> GitHub.Model.GitHubUser -> Html Msg
showSelectSource model user =
    section [ class "mdl-layout " ]
        [ main_ [ class "homepage mdl-layout__content" ]
            [ div [ class "card-login mdl-card mdl-shadow--2dp" ]
                ([ div [ class "mdl-card__title mdl-card--expand mdl-typography--text-center mdl-color--white" ]
                    [ h1 [ class "mdl-color-text--primary" ]
                        [ span [ class "mdl-color-text--black" ] [ text "GitHub" ]
                        , text " Activity"
                        ]
                    ]
                 , div [ class "mdl-card__actions mdl-card--border mdl-color--secondary mdl-color-text--primary" ]
                    [ button
                        [ onClick (ChangeEventSourceCommand (GitHub.Model.GitHubEventSourceUser user.login))
                        , class "mdl-button mdl-button--colored mdl-color-text--primary"
                        ]
                        [ text ("Stream " ++ user.login ++ " user events")
                        ]
                    ]
                 ]
                    ++ organisationButtonList model
                    ++ [ div [ class "mdl-card__actions mdl-card--border mdl-color--secondary mdl-color-text--primary" ]
                            [ button
                                [ onClick (ChangeEventSourceCommand GitHub.Model.GitHubEventSourceDefault)
                                , class "mdl-button mdl-button--colored mdl-color-text--primary"
                                ]
                                [ text "Stream all public events"
                                ]
                            ]
                       , div [ class "mdl-card__actions mdl-card--border mdl-color--primary mdl-color-text--white" ]
                            [ button
                                [ onClick SignOutCommand
                                , class "mdl-button mdl-button--colored mdl-color-text--white"
                                ]
                                [ text "Sign out"
                                ]
                            , div [ class "mdl-layout-spacer" ] []
                            , i [ class "fas fa-sign-out-alt fa-lg left-spaced" ] []
                            ]
                       ]
                )
            ]
        ]


organisationButtonList : Model -> List (Html Msg)
organisationButtonList model =
    model.organisations
        |> List.map organisationButton


organisationButton : GitHub.Model.GitHubOrganisation -> Html Msg
organisationButton organisation =
    div [ class "mdl-card__actions mdl-card--border mdl-color--secondary mdl-color-text--primary" ]
        [ button
            [ onClick (ChangeEventSourceCommand (GitHub.Model.GitHubEventSourceOrganisation organisation.login))
            , class "mdl-button mdl-button--colored mdl-color-text--primary"
            ]
            [ text ("Stream " ++ organisation.login ++ " org events")
            ]
        ]
