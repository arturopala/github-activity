module View exposing (view)

import Html exposing (Html, a, div, h1, i, main_, section, span, text)
import Html.Attributes exposing (..)
import Message exposing (..)
import Model exposing (Model)


view : Model -> Html Msg
view _ =
    section [ class "mdl-layout mdl-js-layout" ]
        [ main_ [ class "welcome mdl-layout__content" ]
            [ div [ class "card-login mdl-card mdl-shadow--2dp" ]
                [ div [ class "mdl-card__title mdl-card--expand mdl-typography--text-center mdl-color--white" ]
                    [ h1 [ class "mdl-color-text--primary" ]
                        [ span [ class "mdl-color-text--black" ] [ text "GitHub" ]
                        , text " Activity"
                        ]
                    ]
                , div [ class "mdl-card__actions mdl-card--border mdl-color--primary mdl-color-text--white" ]
                    [ a
                        [ href "https://github.com/login/oauth/authorize?client_id=22030043f4425febdf23&scope=read:org"
                        , class "mdl-button mdl-button--colored mdl-js-button mdl-js-ripple-effect mdl-color-text--white"
                        ]
                        [ text "Sign in with GitHub"
                        ]
                    , div [ class "mdl-layout-spacer" ] []
                    , i [ class "fab fa-github fa-lg" ] []
                    ]
                ]
            ]
        ]
