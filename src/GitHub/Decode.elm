module GitHub.Decode exposing (decodeActor, decodeDateTime, decodeEvent, decodeEventByType, decodeEvents, decodeGitHubOrganisationInfo, decodeGitHubUserInfo, decodePayload, decodePullRequest, decodePullRequestEventPayload, decodeRelease, decodeReleaseEventPayload, decodeRepo)

import GitHub.Model exposing (..)
import Iso8601 exposing (toTime)
import Json.Decode as Decode exposing (Decoder, andThen, field, int, list, map, string)
import Json.Decode.Pipeline exposing (optional, required)
import Regex exposing (Regex)
import Time exposing (Posix)
import Url


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


decodeActor : Decoder GitHubEventActor
decodeActor =
    Decode.succeed GitHubEventActor
        |> required "display_login" string
        |> required "avatar_url" string


decodeRepo : Decoder GitHubRepoLink
decodeRepo =
    Decode.succeed GitHubRepoLink
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


decodePullRequest : Decoder GitHubPullRequestLink
decodePullRequest =
    Decode.succeed GitHubPullRequestLink
        |> required "url" string
        |> required "id" int


decodeReleaseEventPayload : Decoder GitHubReleaseEventPayload
decodeReleaseEventPayload =
    Decode.succeed GitHubReleaseEventPayload
        |> required "action" string
        |> required "release" decodeRelease


decodeRelease : Decoder GitHubReleaseLink
decodeRelease =
    Decode.succeed GitHubReleaseLink
        |> required "url" string
        |> required "tag_name" string


decodeGitHubUserInfo : Decoder GitHubUserInfo
decodeGitHubUserInfo =
    Decode.succeed GitHubUserInfo
        |> required "login" string
        |> required "avatar_url" decodeUrl
        |> required "url" decodeUrl
        |> required "html_url" decodeUrl
        |> required "organizations_url" decodeUrl
        |> required "repos_url" decodeUrl
        |> required "events_url" decodeUrl
        |> required "received_events_url" decodeUrl
        |> required "type" string
        |> required "name" string
        |> optional "company" string ""
        |> optional "location" string ""
        |> optional "email" string ""
        |> required "public_repos" int
        |> required "public_gists" int
        |> required "followers" int
        |> required "following" int


decodeGitHubOrganisationInfo : Decoder GitHubOrganisationInfo
decodeGitHubOrganisationInfo =
    Decode.succeed GitHubOrganisationInfo
        |> required "login" string
        |> required "id" int
        |> required "node_id" string
        |> required "url" decodeUrl
        |> required "repos_url" decodeUrl
        |> required "events_url" decodeUrl
        |> required "avatar_url" decodeUrl
        |> required "description" string


dummyUrl : Url.Url
dummyUrl =
    Url.Url Url.Http "dummy" Nothing "" Nothing Nothing


decodeUrl : Decoder Url.Url
decodeUrl =
    string |> Decode.map removeUrlPathTemplates |> Decode.map Url.fromString |> Decode.map (Maybe.withDefault dummyUrl)


urlPathTemplateRegex : Regex
urlPathTemplateRegex =
    Regex.fromString "\\{/\\w+?\\}" |> Maybe.withDefault Regex.never


removeUrlPathTemplates : String -> String
removeUrlPathTemplates url =
    Regex.replace urlPathTemplateRegex (\_ -> "") url
