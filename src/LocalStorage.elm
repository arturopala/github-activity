module LocalStorage exposing (decodeAndOverlayState, saveToLocalStorage)

import GitHub.Authorization exposing (Authorization(..))
import GitHub.Model
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode
import Message exposing (Msg)
import Model exposing (Model)
import Ports exposing (..)


type alias LocalState =
    { authorization : Authorization
    , source : GitHub.Model.GitHubEventSource
    , sourceHistory : List GitHub.Model.GitHubEventSource
    }


saveToLocalStorage : Model -> Cmd Msg
saveToLocalStorage model =
    model
        |> toLocalState
        |> encodeAsJson
        |> Encode.encode 2
        |> Ports.storeState


decodeAndOverlayState : Maybe String -> Model -> Maybe Model
decodeAndOverlayState maybeState model =
    maybeState
        |> Maybe.map (Decode.decodeString decodeLocalState)
        |> Maybe.andThen Result.toMaybe
        |> Maybe.map (fromLocalState model)


toLocalState : Model -> LocalState
toLocalState model =
    { authorization = model.authorization
    , source = model.eventStream.source
    , sourceHistory = model.homepage.sourceHistory
    }


fromLocalState : Model -> LocalState -> Model
fromLocalState model state =
    model
        |> Model.authorizationLens.set state.authorization
        |> Model.eventStreamSourceLens.set state.source
        |> Model.homepageSourceHistoryLens.set state.sourceHistory


encodeAsJson : LocalState -> Encode.Value
encodeAsJson state =
    Encode.object
        [ ( "authorization", encodeAuthorization state.authorization )
        , ( "source", encodeSource state.source )
        , ( "sourceHistory", Encode.list encodeSource state.sourceHistory )
        ]


decodeLocalState : Decode.Decoder LocalState
decodeLocalState =
    Decode.succeed LocalState
        |> optional "authorization" decodeAuthorization Unauthorized
        |> optional "source" decodeSource GitHub.Model.GitHubEventSourceDefault
        |> optional "sourceHistory" (Decode.list decodeSource) []


encodeAuthorization : Authorization -> Encode.Value
encodeAuthorization authorization =
    case authorization of
        Unauthorized ->
            Encode.null

        Token token scope ->
            Encode.object [ ( "token", Encode.string token ), ( "scope", Encode.string scope ) ]


decodeAuthorization : Decode.Decoder Authorization
decodeAuthorization =
    Decode.oneOf
        [ Decode.null Unauthorized
        , Decode.succeed Token
            |> required "token" Decode.string
            |> required "scope" Decode.string
        ]


encodeSource : GitHub.Model.GitHubEventSource -> Encode.Value
encodeSource source =
    case source of
        GitHub.Model.GitHubEventSourceDefault ->
            Encode.null

        GitHub.Model.GitHubEventSourceUser user ->
            Encode.object [ ( "user", Encode.string user ) ]

        GitHub.Model.GitHubEventSourceOrganisation org ->
            Encode.object [ ( "organisation", Encode.string org ) ]

        GitHub.Model.GitHubEventSourceRepository owner repo ->
            Encode.object [ ( "repository", Encode.object [ ( "owner", Encode.string owner ), ( "repo", Encode.string repo ) ] ) ]

        GitHub.Model.GitHubEventSourceRepositoryById id ->
            Encode.object [ ( "repository", Encode.object [ ( "id", Encode.string id ) ] ) ]


decodeSource : Decode.Decoder GitHub.Model.GitHubEventSource
decodeSource =
    Decode.oneOf
        [ Decode.succeed GitHub.Model.GitHubEventSourceUser
            |> required "user" Decode.string
        , Decode.succeed GitHub.Model.GitHubEventSourceOrganisation
            |> required "organisation" Decode.string
        , Decode.succeed GitHub.Model.GitHubEventSourceRepository
            |> required "owner" Decode.string
            |> required "repo" Decode.string
        , Decode.succeed GitHub.Model.GitHubEventSourceRepositoryById
            |> required "id" Decode.string
        , Decode.null GitHub.Model.GitHubEventSourceDefault
        ]
