module Components.UserSearch exposing (Model, Msg(..), init, lastQueryLens, resultsLens, searchingLens, subscriptions, update, view)

import GitHub.APIv3
import GitHub.Authorization exposing (Authorization)
import GitHub.Message
import GitHub.Model
import Html exposing (Html, div, i, input, text)
import Html.Attributes exposing (class, classList, id, pattern, placeholder, type_)
import Html.Events exposing (onBlur, onFocus, onInput)
import Http
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
    | UserSearchError Http.Error
    | HttpFetch (Authorization -> Cmd Msg)
    | Clear
    | NoOp


type alias Model =
    { active : Bool
    , input : String
    , searching : Bool
    , results : List GitHub.Model.GitHubUserRef
    , lastQuery : String
    , error : Maybe Http.Error
    }


init : Model
init =
    { active = False
    , input = ""
    , searching = False
    , results = []
    , lastQuery = ""
    , error = Nothing
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
                if not model.searching then
                    searchUser model

                else
                    ( model, Cmd.none )

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
                |> errorLens.set Nothing
            , Cmd.none
            )

        UserSearchError error ->
            ( model
                |> searchingLens.set False
                |> errorLens.set (Just error)
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
            |> errorLens.set Nothing
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
            |> errorLens.set Nothing
        , Cmd.none
        )


gitHubApiResponseAsMsg : GitHub.Message.Msg -> Msg
gitHubApiResponseAsMsg msg =
    case msg of
        GitHub.Message.GitHubUserSearchMsg (Ok response) ->
            UserSearchResultEvent response.content.items

        GitHub.Message.GitHubUserSearchMsg (Err ( error, limits )) ->
            UserSearchError error

        _ ->
            NoOp


view : Model -> Html Msg
view model =
    div [ class "search-box mdl-color-text--primary" ]
        [ div [ class "search-input-box" ]
            [ if Util.isDefined model.error then
                i
                    [ classList
                        [ ( "search-icon", True )
                        , ( "mdi mdi-24px", True )
                        , ( errorMdiIconCssClass model.error, True )
                        , ( "search-icon-error", True )
                        ]
                    ]
                    []

              else
                i
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


errorMdiIconCssClass : Maybe Http.Error -> String
errorMdiIconCssClass error =
    case error of
        Just Http.NetworkError ->
            "mdi-cloud-off-outline"

        Just Http.Timeout ->
            "mdi-cloud-alert"

        Just _ ->
            "mdi-cloud-question"

        Nothing ->
            ""


resultsLens : Lens Model (List GitHub.Model.GitHubUserRef)
resultsLens =
    Lens .results (\b a -> { a | results = b })


searchingLens : Lens Model Bool
searchingLens =
    Lens .searching (\b a -> { a | searching = b })


lastQueryLens : Lens Model String
lastQueryLens =
    Lens .lastQuery (\b a -> { a | lastQuery = b })


errorLens : Lens Model (Maybe Http.Error)
errorLens =
    Lens .error (\b a -> { a | error = b })
