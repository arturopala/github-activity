module Components.UserSearch exposing (Model, Msg(..), init, lastQueryLens, resultsLens, searchingLens, subscriptions, update, view)

import GitHub.API
import GitHub.API3Request
import GitHub.Authorization exposing (Authorization)
import GitHub.Handlers as Handlers exposing (Handlers)
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
    | GotUserSearchResult (GitHub.Model.GitHubSearchResult GitHub.Model.GitHubUserRef)
    | ConnectionErrorEvent
    | UsersNotFoundEvent
    | ResultParsingErrorEvent
    | OtherErrorEvent
    | HttpFetch (Authorization -> Cmd GitHub.API3Request.GitHubResponse)
    | Clear
    | NoOp


type Error
    = NoConnection
    | NotFound
    | ParsingError
    | OtherError


type alias Model =
    { active : Bool
    , input : String
    , searching : Bool
    , results : List GitHub.Model.GitHubUserRef
    , lastQuery : String
    , error : Maybe Error
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

        GotUserSearchResult result ->
            ( if model.searching then
                model
                    |> resultsLens.set result.items
                    |> searchingLens.set False
                    |> errorLens.set Nothing

              else
                model
            , Cmd.none
            )

        ConnectionErrorEvent ->
            if model.active && String.length model.input > 2 then
                ( model
                    |> searchingLens.set False
                    |> errorLens.set (Just NoConnection)
                , Util.delayMessage 5 (HttpFetch (GitHub.API3Request.searchUsersByLogin model.input))
                )

            else
                ( model
                    |> searchingLens.set False
                , Cmd.none
                )

        UsersNotFoundEvent ->
            ( model
                |> resultsLens.set []
                |> searchingLens.set False
                |> errorLens.set (Just NotFound)
            , Cmd.none
            )

        ResultParsingErrorEvent ->
            ( model
                |> resultsLens.set []
                |> searchingLens.set False
                |> errorLens.set (Just ParsingError)
            , Cmd.none
            )

        OtherErrorEvent ->
            ( model
                |> resultsLens.set []
                |> searchingLens.set False
                |> errorLens.set (Just OtherError)
            , Cmd.none
            )

        Clear ->
            ( init, Cmd.none )

        HttpFetch _ ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


handlers : Handlers GitHub.API.Endpoint String (GitHub.Model.GitHubSearchResult GitHub.Model.GitHubUserRef) Msg
handlers =
    Handlers.emptyHandlers NoOp


searchUser : Model -> ( Model, Cmd Msg )
searchUser model =
    if String.length model.input > 2 then
        ( model
            |> lastQueryLens.set model.input
            |> resultsLens.set []
            |> searchingLens.set True
            |> errorLens.set Nothing
        , push <|
            HttpFetch (GitHub.API3Request.searchUsersByLogin model.input)
        )

    else
        ( model
            |> resultsLens.set []
            |> lastQueryLens.set ""
            |> searchingLens.set False
            |> errorLens.set Nothing
        , Cmd.none
        )


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


errorMdiIconCssClass : Maybe Error -> String
errorMdiIconCssClass error =
    case error of
        Just NoConnection ->
            "mdi-cloud-off-outline"

        Just NotFound ->
            "mdi-emoticon-sad-outline"

        Just ParsingError ->
            "mdi-cloud-question"

        Just OtherError ->
            "mdi-cloud-alert"

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


errorLens : Lens Model (Maybe Error)
errorLens =
    Lens .error (\b a -> { a | error = b })
