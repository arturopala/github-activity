module Components.UserSearch exposing (Model, Msg(..), init, lastQueryLens, resultsLens, searchingLens, subscriptions, update, view)

import GitHub.APIv3
import GitHub.Authorization exposing (Authorization)
import GitHub.Message
import GitHub.Model
import Html exposing (Html, div, i, input, text)
import Html.Attributes exposing (class, classList, id, pattern, placeholder, type_)
import Html.Events exposing (onBlur, onFocus, onInput)
import Monocle.Lens exposing (Lens)
import Time
import Util exposing (onKeyUp, push)


type Msg
    = InputEvent String
    | BlurEvent
    | KeyEvent String
    | FocusEvent
    | TickEvent
    | UserSearchResultEvent (List GitHub.Model.GitHubUserRef)
    | HttpFetch (Authorization -> Cmd Msg)
    | Clear
    | NoOp


type alias Model =
    { active : Bool
    , input : String
    , searching : Bool
    , results : List GitHub.Model.GitHubUserRef
    , lastQuery : String
    }


init : Model
init =
    { active = False
    , input = ""
    , searching = False
    , results = []
    , lastQuery = ""
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.active then
        Time.every 3000 (\_ -> TickEvent)

    else
        Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputEvent input ->
            ( { model | input = input }, Cmd.none )

        FocusEvent ->
            ( { model | active = True }, Cmd.none )

        BlurEvent ->
            ( { model | active = False }, Cmd.none )

        KeyEvent key ->
            if Util.isEscapeKey key then
                ( init, Cmd.none )

            else if Util.isEnterKey key then
                searchUser model

            else
                ( model, Cmd.none )

        TickEvent ->
            if not model.searching && model.input /= model.lastQuery then
                searchUser model

            else
                ( model, Cmd.none )

        UserSearchResultEvent users ->
            ( model
                |> resultsLens.set users
                |> searchingLens.set False
            , Cmd.none
            )

        Clear ->
            ( init, Cmd.none )

        HttpFetch _ ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


searchUser : Model -> ( Model, Cmd Msg )
searchUser model =
    if String.length model.input > 2 then
        ( model
            |> lastQueryLens.set model.input
            |> resultsLens.set []
            |> searchingLens.set True
        , push <|
            HttpFetch
                (\t ->
                    GitHub.APIv3.searchUsersByLogin model.input t
                        |> Cmd.map gitHubApiResponseAsMsg
                )
        )

    else
        ( model
            |> resultsLens.set []
            |> lastQueryLens.set ""
        , Cmd.none
        )


gitHubApiResponseAsMsg : GitHub.Message.Msg -> Msg
gitHubApiResponseAsMsg msg =
    case msg of
        GitHub.Message.GitHubUserSearchMsg (Ok response) ->
            UserSearchResultEvent response.content.items

        _ ->
            NoOp


view : Model -> Html Msg
view model =
    div [ class "search-box mdl-color-text--primary" ]
        [ div [ class "search-input-box" ]
            [ i
                [ classList
                    [ ( "search-icon", True )
                    , ( "material-icons", True )
                    , ( "search-icon-searching", model.searching )
                    ]
                ]
                [ text "search" ]
            , input
                [ class "search-input"
                , type_ "text"
                , pattern "[a-zA-Z0-9-]*"
                , id "search"
                , placeholder "Type to search for new streams"
                , onFocus FocusEvent
                , onBlur BlurEvent
                , onInput InputEvent
                , onKeyUp KeyEvent
                ]
                []
            ]
        ]


resultsLens : Lens Model (List GitHub.Model.GitHubUserRef)
resultsLens =
    Lens .results (\b a -> { a | results = b })


searchingLens : Lens Model Bool
searchingLens =
    Lens .searching (\b a -> { a | searching = b })


lastQueryLens : Lens Model String
lastQueryLens =
    Lens .lastQuery (\b a -> { a | lastQuery = b })
