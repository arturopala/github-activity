module Github.APIv3 exposing (readGithubEvents)

import Http
import Dict exposing (Dict)
import Json.Decode exposing (decodeString)
import Github.Message exposing (Msg(..))
import Github.Decode exposing (decodeEvents)
import Github.Model exposing (..)


readGithubEvents : GithubEventSource -> String -> Cmd Msg
readGithubEvents source etag =
    case source of
        GithubUser user ->
            Http.send GotEvents (getEventsWithIntervalRequest ("users/" ++ user) etag)


getEventsWithIntervalRequest : String -> String -> Http.Request GithubEventsResponse
getEventsWithIntervalRequest path etag =
    Http.request
        { method = "GET"
        , headers =
            [ Http.header "If-None-Match" etag
            ]
        , url = ("https://api.github.com/" ++ path ++ "/events")
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
