module GitHub.OAuth exposing (Msg(..), requestAccessToken, signInUrl)

import Http
import Json.Decode as Decode exposing (Decoder, andThen, bool, decodeString, field, map, string)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode


type Msg
    = OAuthToken String String
    | OAuthError String


type Error
    = String


signInUrl : String
signInUrl =
    "https://github.com/login/oauth/authorize?client_id=22030043f4425febdf23&scope=read:org%20read:user"


oAuthUrl : String
oAuthUrl =
    "https://00gigun9fl.execute-api.eu-central-1.amazonaws.com/default/github-oauth-proxy"


requestAccessToken : String -> Cmd Msg
requestAccessToken code =
    Http.request
        { method = "POST"
        , headers =
            [ Http.header "Accept" "application/json"
            , Http.header "Content-Type" "application/json"
            ]
        , url = oAuthUrl
        , body = Http.jsonBody (preparePayload code)
        , expect = Http.expectStringResponse toMsg processResponse
        , timeout = Nothing
        , tracker = Nothing
        }


toMsg : Result String Msg -> Msg
toMsg result =
    case result of
        Ok msg ->
            msg

        Err error ->
            OAuthError error


preparePayload : String -> Encode.Value
preparePayload code =
    Encode.object
        [ ( "code", Encode.string code )
        ]


processResponse : Http.Response String -> Result String Msg
processResponse response =
    case response of
        Http.GoodStatus_ metadata body ->
            decodeString decodeResponse body
                |> Result.mapError Decode.errorToString

        Http.BadUrl_ url ->
            Err ("Bad URL " ++ url)

        Http.Timeout_ ->
            Err "Timeout"

        Http.NetworkError_ ->
            Err "Network error"

        Http.BadStatus_ metadata body ->
            Err ("Bad status " ++ String.fromInt metadata.statusCode)


decodeResponse : Decoder Msg
decodeResponse =
    let
        decodeByCase success =
            case success of
                True ->
                    decodeToken

                False ->
                    map OAuthError (field "error" string)
    in
    field "success" bool
        |> andThen decodeByCase


decodeToken : Decoder Msg
decodeToken =
    Decode.succeed OAuthToken
        |> required "token" string
        |> required "scope" string
