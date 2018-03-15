module Github.Decode exposing (..)

import Json.Decode exposing (int, string, float, Decoder, decodeString, list, nullable, map, fail, andThen, field)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Github.Model exposing (..)
import Time.DateTime as DateTime


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
