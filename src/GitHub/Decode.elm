module GitHub.Decode exposing (decodeActor, decodeDateTime, decodeEvent, decodeEventByType, decodeEvents, decodePayload, decodePullRequest, decodePullRequestEventPayload, decodeRelease, decodeReleaseEventPayload, decodeRepo)

import GitHub.Model exposing (..)
import Iso8601 exposing (toTime)
import Json.Decode as Decode exposing (Decoder, andThen, field, int, list, map, string)
import Json.Decode.Pipeline exposing (required)
import Time exposing (Posix)


decodeEvents : Decoder (List GitHubEvent)
decodeEvents =
    list decodeEvent


decodeEvent : Decoder GitHubEvent
decodeEvent =
    field "type" string
        |> andThen decodeEventByType


decodeEventByType : String -> Decoder GitHubEvent
decodeEventByType t =
    Decode.succeed GitHubEvent
        |> required "id" string
        |> required "type" string
        |> required "actor" decodeActor
        |> required "repo" decodeRepo
        |> required "payload" (decodePayload t)
        |> required "created_at" decodeDateTime


decodeActor : Decoder GitHubActor
decodeActor =
    Decode.succeed GitHubActor
        |> required "display_login" string
        |> required "avatar_url" string


decodeRepo : Decoder GitHubRepo
decodeRepo =
    Decode.succeed GitHubRepo
        |> required "name" string
        |> required "url" string


decodePayload : String -> Decoder GitHubEventPayload
decodePayload tag =
    case tag of
        "PullRequestEvent" ->
            map GitHubPullRequestEvent decodePullRequestEventPayload

        "ReleaseEvent" ->
            map GitHubReleaseEvent decodeReleaseEventPayload

        _ ->
            Decode.succeed GitHubOtherEventPayload


decodeDateTime : Decoder Posix
decodeDateTime =
    map (toTime >> Result.withDefault (Time.millisToPosix 0)) string


decodePullRequestEventPayload : Decoder GitHubPullRequestEventPayload
decodePullRequestEventPayload =
    Decode.succeed GitHubPullRequestEventPayload
        |> required "action" string
        |> required "pull_request" decodePullRequest


decodePullRequest : Decoder GitHubPullRequest
decodePullRequest =
    Decode.succeed GitHubPullRequest
        |> required "url" string
        |> required "id" int


decodeReleaseEventPayload : Decoder GitHubReleaseEventPayload
decodeReleaseEventPayload =
    Decode.succeed GitHubReleaseEventPayload
        |> required "action" string
        |> required "release" decodeRelease


decodeRelease : Decoder GitHubRelease
decodeRelease =
    Decode.succeed GitHubRelease
        |> required "url" string
        |> required "tag_name" string
