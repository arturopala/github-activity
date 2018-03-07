module Github exposing (readGithubEvents)

import Http
import Json.Decode exposing (int, string, float, Decoder, decodeString, list, nullable, map, fail, andThen, field)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Model exposing (..)
import Message exposing (..)
import Time.DateTime as DateTime
import Dict exposing (Dict)

readGithubEvents : String  -> String -> Cmd Msg
readGithubEvents path etag =
    Http.send GotEvents (getEventsWithIntervalRequest path etag)


getEventsWithIntervalRequest : String -> String -> Http.Request EventsResponse
getEventsWithIntervalRequest path etag =
    Http.request
        { method = "GET"
        , headers = [
            Http.header "If-None-Match" etag
        ]
        , url = ("https://api.github.com" ++ path)
        , body = Http.emptyBody
        , expect = Http.expectStringResponse getEventsResponse
        , timeout = Nothing
        , withCredentials = False
        }  


getEventsResponse : Http.Response String -> Result String EventsResponse
getEventsResponse response =
    decodeString decodeEvents response.body
    |> Result.map (\events -> EventsResponse events 
        (getPollInterval response.headers) (getETag response.headers)
    )


getPollInterval : Dict String String -> Int
getPollInterval headers = 
    let
       _  = Debug.log "headers" headers      
    in
        headers
        |> Dict.get "x-poll-interval"
        |> Maybe.andThen (String.toInt >> Result.toMaybe)
        |> Maybe.withDefault 120


getETag : Dict String String -> String
getETag headers = 
    headers
    |> Dict.get "etag"
    |> Maybe.withDefault ""


decodeEvents : Decoder (List GithubEvent)
decodeEvents =
    list decodeEvent


decodeEvent : Decoder GithubEvent
decodeEvent =
    field "type" string
    |> andThen decodeEventByType


decodeEventByType : String -> Decoder GithubEvent
decodeEventByType t =
    decode GithubEvent
        |> required "id" string
        |> required "type" string
        |> required "actor" decodeActor
        |> required "repo" decodeRepo
        |> required "payload" (decodePayload t) 
        |> required "created_at" decodeDateTime


decodeActor : Decoder GithubActor
decodeActor =
    decode GithubActor
        |> required "display_login" string
        |> required "avatar_url" string


decodeRepo : Decoder GithubRepo
decodeRepo =
    decode GithubRepo
        |> required "name" string
        |> required "url" string


decodePayload : String -> Decoder GithubEventPayload
decodePayload tag =
    case tag of
        "PullRequestEvent" ->
            map GithubPullRequestEvent decodePullRequestEventPayload

        "ReleaseEvent" ->
            map GithubReleaseEvent decodeReleaseEventPayload

        _ ->
            decode GithubOtherEventPayload


decodeDateTime : Decoder DateTime.DateTime
decodeDateTime =
    map (DateTime.fromISO8601 >> Result.withDefault DateTime.epoch) string


decodePullRequestEventPayload : Decoder GithubPullRequestEventPayload
decodePullRequestEventPayload =
    decode GithubPullRequestEventPayload
        |> required "action" string
        |> required "pull_request" decodePullRequest


decodePullRequest : Decoder GithubPullRequest
decodePullRequest =
    decode GithubPullRequest
        |> required "url" string
        |> required "id" int


decodeReleaseEventPayload : Decoder GithubReleaseEventPayload
decodeReleaseEventPayload =
    decode GithubReleaseEventPayload
        |> required "action" string
        |> required "release" decodeRelease


decodeRelease : Decoder GithubRelease
decodeRelease =
    decode GithubRelease
        |> required "url" string
        |> required "tag_name" string
