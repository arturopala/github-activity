module GitHub.APIv3 exposing (readGitHubEvents, readGitHubEventsNextPage)

import Dict exposing (Dict)
import GitHub.Decode exposing (decodeEvents)
import GitHub.Message exposing (Msg(..))
import GitHub.Model exposing (..)
import Http
import Json.Decode exposing (decodeString, errorToString)
import Url exposing (Url)


type alias ResultToMsg a =
    Result Http.Error a -> Msg


type alias DecodeHttpResponse a =
    Http.Response String -> Result Http.Error a


githubApiUrl : Url
githubApiUrl =
    Url Url.Https "api.github.com" Nothing "" Nothing Nothing


readGitHubEvents : GitHubEventSource -> String -> Maybe String -> Cmd Msg
readGitHubEvents source etag tokenOpt =
    case source of
        None ->
            Cmd.none

        GitHubUser user ->
            httpGet { githubApiUrl | path = "/users/" ++ user ++ "/events" } etag tokenOpt GotEventsChunk decodeEventsResponse


readGitHubEventsNextPage : Url -> String -> Maybe String -> Cmd Msg
readGitHubEventsNextPage url etag tokenOpt =
    httpGet url etag tokenOpt GotEventsChunk decodeEventsResponse


httpGet : Url -> String -> Maybe String -> ResultToMsg a -> DecodeHttpResponse a -> Cmd Msg
httpGet url etag tokenOpt resultToMsg decodeHttpResponse =
    let
        headers =
            [ Http.header "If-None-Match" etag ]
                ++ (tokenOpt
                        |> Maybe.map (\t -> [ Http.header "Authorization" ("token " ++ t) ])
                        |> Maybe.withDefault []
                   )
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = Url.toString url
        , body = Http.emptyBody
        , expect = Http.expectStringResponse resultToMsg decodeHttpResponse
        , timeout = Nothing
        , tracker = Nothing
        }


decodeEventsResponse : Http.Response String -> Result Http.Error GitHubEventsChunk
decodeEventsResponse response =
    case response of
        Http.GoodStatus_ metadata body ->
            decodeString decodeEvents body
                |> Result.map
                    (\events ->
                        GitHubEventsChunk events
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
