module GitHub.Decode exposing (decodeActor, decodeDateTime, decodeEvent, decodeEventByType, decodeEvents, decodeGitHubAuthor, decodeGitHubCommit, decodeOrganisation, decodePayload, decodePullRequest, decodePullRequestEventPayload, decodePushEventPayload, decodeReleaseEventPayload, decodeReleaseRef, decodeRepoLink, decodeRepository, decodeUser, decodeUserRef)

import GitHub.Model exposing (..)
import Iso8601 exposing (toTime)
import Json.Decode as Decode exposing (Decoder, andThen, bool, field, int, list, map, maybe, string)
import Json.Decode.Pipeline exposing (optional, required)
import Regex exposing (Regex)
import Time exposing (Posix)
import Url


notrequi : String -> Decoder a -> Decoder (Maybe a -> b) -> Decoder b
notrequi key valDecoder decoder =
    optional key (maybe valDecoder) Nothing decoder


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
        |> required "repo" decodeRepoLink
        |> required "payload" (decodePayload t)
        |> required "created_at" decodeDateTime


decodeActor : Decoder GitHubEventActor
decodeActor =
    Decode.succeed GitHubEventActor
        |> required "display_login" string
        |> required "avatar_url" string


decodeRepoLink : Decoder GitHubRepoRef
decodeRepoLink =
    Decode.succeed GitHubRepoRef
        |> required "id" int
        |> required "name" string
        |> required "url" decodeUrl


decodeRepository : Decoder GitHubRepository
decodeRepository =
    Decode.succeed GitHubRepository
        |> required "id" int
        |> required "name" string
        |> required "full_name" string
        |> required "url" decodeUrl
        |> required "html_url" decodeUrl
        |> required "events_url" decodeUrl
        |> required "owner" decodeUserRef
        |> required "private" bool
        |> required "fork" bool
        |> required "forks_count" int
        |> required "watchers_count" int
        |> notrequi "subscribers_count" int
        |> notrequi "network_count" int
        |> required "size" int
        |> required "open_issues_count" int
        |> required "default_branch" string
        |> optional "topics" (list string) []
        |> required "created_at" decodeDateTime
        |> required "updated_at" decodeDateTime
        |> required "pushed_at" decodeDateTime


decodePayload : String -> Decoder GitHubEventPayload
decodePayload tag =
    case tag of
        "PullRequestEvent" ->
            map GitHubPullRequestEvent decodePullRequestEventPayload

        "ReleaseEvent" ->
            map GitHubReleaseEvent decodeReleaseEventPayload

        "PushEvent" ->
            map GitHubPushEvent decodePushEventPayload

        _ ->
            Decode.succeed GitHubOtherEventPayload


decodeDateTime : Decoder Posix
decodeDateTime =
    map (toTime >> Result.withDefault (Time.millisToPosix 0)) string


decodePullRequestEventPayload : Decoder GitHubPullRequestEventPayload
decodePullRequestEventPayload =
    Decode.succeed GitHubPullRequestEventPayload
        |> required "action" string
        |> required "number" int
        |> required "pull_request" decodePullRequest


decodePullRequest : Decoder GitHubPullRequest
decodePullRequest =
    Decode.succeed GitHubPullRequest
        |> required "id" int
        |> required "url" decodeUrl
        |> required "html_url" decodeUrl
        |> required "diff_url" decodeUrl
        |> required "commits_url" decodeUrl
        |> required "comments_url" decodeUrl
        |> required "state" string
        |> required "title" string
        |> required "body" string
        |> required "created_at" decodeDateTime
        |> notrequi "merged_at" decodeDateTime
        |> notrequi "merged_commit_sha" string
        |> required "user" decodeUserRef
        |> notrequi "assignee" decodeUserRef
        |> optional "assignees" (list decodeUserRef) []
        |> optional "requested_reviewers" (list decodeUserRef) []
        |> required "merged" bool
        |> notrequi "mergeable" bool
        |> notrequi "rebaseable" bool
        |> required "mergeable_state" string
        |> notrequi "merged_by" decodeUserRef
        |> required "comments" int
        |> required "review_comments" int
        |> required "commits" int
        |> required "additions" int
        |> required "deletions" int
        |> required "changed_files" int
        |> required "head" decodeReference
        |> required "base" decodeReference


decodeReleaseEventPayload : Decoder GitHubReleaseEventPayload
decodeReleaseEventPayload =
    Decode.succeed GitHubReleaseEventPayload
        |> required "action" string
        |> required "release" decodeReleaseRef


decodePushEventPayload : Decoder GitHubPushEventPayload
decodePushEventPayload =
    Decode.succeed GitHubPushEventPayload
        |> required "ref" string
        |> required "head" string
        |> required "before" string
        |> required "size" int
        |> required "distinct_size" int
        |> required "commits" (list decodeGitHubCommit)


decodeGitHubCommit : Decoder GitHubCommit
decodeGitHubCommit =
    Decode.succeed GitHubCommit
        |> required "sha" string
        |> required "message" string
        |> required "author" decodeGitHubAuthor
        |> required "url" decodeUrl
        |> required "distinct" bool


decodeGitHubAuthor : Decoder GitHubAuthor
decodeGitHubAuthor =
    Decode.succeed GitHubAuthor
        |> required "name" string
        |> required "email" string


decodeReleaseRef : Decoder GitHubReleaseRef
decodeReleaseRef =
    Decode.succeed GitHubReleaseRef
        |> required "id" int
        |> required "url" decodeUrl
        |> required "html_url" decodeUrl
        |> required "tag_name" string
        |> notrequi "body" string
        |> required "draft" bool
        |> required "prerelease" bool


decodeUser : Decoder GitHubUser
decodeUser =
    Decode.succeed GitHubUser
        |> required "id" int
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


decodeUserRef : Decoder GitHubUserRef
decodeUserRef =
    Decode.succeed GitHubUserRef
        |> required "id" int
        |> required "login" string
        |> required "avatar_url" decodeUrl
        |> required "url" decodeUrl
        |> required "html_url" decodeUrl
        |> required "type" string


decodeOrganisation : Decoder GitHubOrganisation
decodeOrganisation =
    Decode.succeed GitHubOrganisation
        |> required "login" string
        |> required "id" int
        |> required "node_id" string
        |> required "url" decodeUrl
        |> required "repos_url" decodeUrl
        |> required "events_url" decodeUrl
        |> required "avatar_url" decodeUrl
        |> required "description" string


decodeReference : Decoder GitHubReference
decodeReference =
    Decode.succeed GitHubReference
        |> required "label" string
        |> required "ref" string
        |> required "sha" string
        |> required "user" decodeUserRef
        |> required "repo" decodeRepository


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
