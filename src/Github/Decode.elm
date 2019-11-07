module Github.Decode exposing (decodeActor, decodeDateTime, decodeEvent, decodeEventByType, decodeEvents, decodePayload, decodePullRequest, decodePullRequestEventPayload, decodeRelease, decodeReleaseEventPayload, decodeRepo)

import Github.Model exposing (..)
import Iso8601 exposing (toTime)
import Json.Decode as Decode exposing (Decoder, andThen, field, int, list, map, string)
import Json.Decode.Pipeline exposing (required)
import Time exposing (Posix)


decodeEvents : Decoder (List GithubEvent)
decodeEvents =
    list decodeEvent


decodeEvent : Decoder GithubEvent
decodeEvent =
    field "type" string
        |> andThen decodeEventByType


decodeEventByType : String -> Decoder GithubEvent
decodeEventByType t =
    Decode.succeed GithubEvent
        |> required "id" string
        |> required "type" string
        |> required "actor" decodeActor
        |> required "repo" decodeRepo
        |> required "payload" (decodePayload t)
        |> required "created_at" decodeDateTime


decodeActor : Decoder GithubActor
decodeActor =
    Decode.succeed GithubActor
        |> required "display_login" string
        |> required "avatar_url" string


decodeRepo : Decoder GithubRepo
decodeRepo =
    Decode.succeed GithubRepo
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
            Decode.succeed GithubOtherEventPayload


decodeDateTime : Decoder Posix
decodeDateTime =
    map (toTime >> Result.withDefault (Time.millisToPosix 0)) string


decodePullRequestEventPayload : Decoder GithubPullRequestEventPayload
decodePullRequestEventPayload =
    Decode.succeed GithubPullRequestEventPayload
        |> required "action" string
        |> required "pull_request" decodePullRequest


decodePullRequest : Decoder GithubPullRequest
decodePullRequest =
    Decode.succeed GithubPullRequest
        |> required "url" string
        |> required "id" int


decodeReleaseEventPayload : Decoder GithubReleaseEventPayload
decodeReleaseEventPayload =
    Decode.succeed GithubReleaseEventPayload
        |> required "action" string
        |> required "release" decodeRelease


decodeRelease : Decoder GithubRelease
decodeRelease =
    Decode.succeed GithubRelease
        |> required "url" string
        |> required "tag_name" string
