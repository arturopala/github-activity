module LocalStorage exposing (decodeAndOverlayState, extractAndSaveState)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Message exposing (Msg)
import Model exposing (Model)
import Ports exposing (..)


type alias LocalState =
    { authorization : Model.Authorization
    }


defaultLocalState : LocalState
defaultLocalState =
    LocalState Model.Unauthorized


extractAndSaveState : Model -> Cmd Msg
extractAndSaveState model =
    model
        |> toLocalState
        |> encodeAsJson
        |> Encode.encode 2
        |> Ports.storeState


decodeAndOverlayState : Maybe String -> Model -> Model
decodeAndOverlayState maybeState model =
    case maybeState of
        Just state ->
            state
                |> Decode.decodeString decodeLocalState
                |> Result.withDefault defaultLocalState
                |> fromLocalState model

        Nothing ->
            model


toLocalState : Model -> LocalState
toLocalState model =
    LocalState model.authorization


fromLocalState : Model -> LocalState -> Model
fromLocalState model state =
    model
        |> Model.authorizationLens.set state.authorization


encodeAsJson : LocalState -> Encode.Value
encodeAsJson state =
    Encode.object [ ( "authorization", encodeAuthorization state.authorization ) ]


decodeLocalState : Decode.Decoder LocalState
decodeLocalState =
    Decode.succeed LocalState
        |> required "authorization" decodeAuthorization


encodeAuthorization : Model.Authorization -> Encode.Value
encodeAuthorization authorization =
    case authorization of
        Model.Unauthorized ->
            Encode.null

        Model.Token token scope ->
            Encode.object [ ( "token", Encode.string token ), ( "scope", Encode.string scope ) ]


decodeAuthorization : Decode.Decoder Model.Authorization
decodeAuthorization =
    Decode.oneOf
        [ Decode.null Model.Unauthorized
        , Decode.succeed Model.Token
            |> required "token" Decode.string
            |> required "scope" Decode.string
        ]
