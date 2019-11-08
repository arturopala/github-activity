module GitHub.APIv3 exposing (readCurrentUserInfo, readGitHubEvents, readGitHubEventsNextPage)

import Dict exposing (Dict)
import GitHub.Decode exposing (decodeEvents, decodeGitHubUserInfo)
import GitHub.Message exposing (Msg(..))
import GitHub.Model exposing (..)
import Http
import Json.Decode exposing (Decoder, decodeString, errorToString)
import Model exposing (Authorization(..))
import Url exposing (Url)


type alias ResultToMsg a =
    Result Http.Error (GitHubResponse a) -> Msg


githubApiUrl : Url
githubApiUrl =
    Url Url.Https "api.github.com" Nothing "" Nothing Nothing


readGitHubEvents : GitHubEventSource -> String -> Authorization -> Cmd Msg
readGitHubEvents source etag auth =
    case source of
        GitHubEventSourceDefault ->
            httpGet { githubApiUrl | path = "/events" } etag auth GitHubEventsMsg decodeEvents

        GitHubEventSourceUser user ->
            httpGet { githubApiUrl | path = "/users/" ++ user ++ "/events" } etag auth GitHubEventsMsg decodeEvents


readGitHubEventsNextPage : Url -> String -> Authorization -> Cmd Msg
readGitHubEventsNextPage url etag auth =
    httpGet url etag auth GitHubEventsMsg decodeEvents


readCurrentUserInfo : Authorization -> Cmd Msg
readCurrentUserInfo auth =
    httpGet { githubApiUrl | path = "/user" } "" auth GitHubUserMsg decodeGitHubUserInfo


httpGet : Url -> String -> Authorization -> ResultToMsg a -> Decoder a -> Cmd Msg
httpGet url etag auth resultToMsg decoder =
    let
        headers =
            [ Http.header "If-None-Match" etag ]
                ++ (case auth of
                        Token token scope ->
                            [ Http.header "Authorization" ("token " ++ token) ]

                        Unauthorized ->
                            []
                   )
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = Url.toString url
        , body = Http.emptyBody
        , expect = Http.expectStringResponse resultToMsg (decodeGitHubResponse decoder)
        , timeout = Nothing
        , tracker = Nothing
        }


decodeGitHubResponse : Decoder a -> Http.Response String -> Result Http.Error (GitHubResponse a)
decodeGitHubResponse decoder response =
    case response of
        Http.GoodStatus_ metadata body ->
            decodeString decoder body
                |> Result.map
                    (\content ->
                        GitHubResponse content
                            (getPollInterval metadata.headers)
                            (getETag metadata.headers)
                            (getLinks metadata.headers)
                    )
                |> Result.mapError (\e -> Http.BadBody (errorToString e))

        Http.BadUrl_ url ->
            Err (Http.BadUrl ("Bad URL " ++ url))

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError

        Http.BadStatus_ metadata body ->
            Err (Http.BadStatus metadata.statusCode)


getPollInterval : Dict String String -> Int
getPollInterval headers =
    headers
        |> Dict.get "x-poll-interval"
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 120


getETag : Dict String String -> String
getETag headers =
    headers
        |> Dict.get "etag"
        |> Maybe.withDefault ""


getLinks : Dict String String -> Dict String String
getLinks headers =
    headers
        |> Dict.get "link"
        |> Maybe.withDefault ""
        |> String.split ","
        |> List.map (String.split ";")
        |> List.map
            (\s ->
                ( s |> List.head |> Maybe.withDefault "<>" |> String.trim |> String.slice 1 -1
                , s |> List.tail |> Maybe.andThen List.head |> Maybe.withDefault "rel=\"link\"" |> String.trim |> String.slice 5 -1
                )
            )
        |> List.map (\t -> ( Tuple.second t, Tuple.first t ))
        |> Dict.fromList
