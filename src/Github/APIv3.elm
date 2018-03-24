module Github.APIv3 exposing (readGithubEvents, readGithubEventsNextPage)

import Http
import Dict exposing (Dict)
import Json.Decode exposing (decodeString)
import Github.Message exposing (Msg(..))
import Github.Decode exposing (decodeEvents)
import Github.Model exposing (..)


githubApiUrl : String
githubApiUrl =
    "https://api.github.com"


readGithubEvents : GithubEventSource -> String -> Cmd Msg
readGithubEvents source etag =
    case source of
        GithubUser user ->
            Http.send GotEvents (getEventsWithIntervalRequest (githubApiUrl ++ "/users/" ++ user ++ "/events") etag)


readGithubEventsNextPage : String -> Cmd Msg
readGithubEventsNextPage url =
    Http.send GotEvents (getEventsWithIntervalRequest url "")


getEventsWithIntervalRequest : String -> String -> Http.Request GithubEventsResponse
getEventsWithIntervalRequest url etag =
    Http.request
        { method = "GET"
        , headers =
            [ Http.header "If-None-Match" etag
            ]
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectStringResponse getEventsResponse
        , timeout = Nothing
        , withCredentials = False
        }


getEventsResponse : Http.Response String -> Result String GithubEventsResponse
getEventsResponse response =
    decodeString decodeEvents response.body
        |> Result.map
            (\events ->
                GithubEventsResponse events
                    (getPollInterval response.headers)
                    (getETag response.headers)
                    (getLinks response.headers)
            )


getPollInterval : Dict String String -> Int
getPollInterval headers =
    headers
        |> Dict.get "x-poll-interval"
        |> Maybe.andThen (String.toInt >> Result.toMaybe)
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
                , s |> List.tail |> Maybe.andThen List.head |> Maybe.withDefault "rel=\"link\""  |> String.trim |> String.slice 5 -1
                )
            )
        |> List.map (\t -> ( Tuple.second t, Tuple.first t ))
        |> Dict.fromList
