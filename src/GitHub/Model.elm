module GitHub.Model exposing (GitHubApiLimits, GitHubError, GitHubEvent, GitHubEventActor, GitHubEventPayload(..), GitHubEventSource(..), GitHubEventsChunk, GitHubPullRequestEventPayload, GitHubPullRequestLink, GitHubReleaseEventPayload, GitHubReleaseLink, GitHubRepoLink, GitHubResponse, GitHubUserInfo)

import Dict exposing (Dict)
import Time exposing (Posix)
import Url exposing (Url)


type alias GitHubResponse a =
    { content : a
    , etag : String
    , links : Dict String String
    , limits : GitHubApiLimits
    }


type alias GitHubApiLimits =
    { xRateLimit : Int
    , xRateRemaining : Int
    , xRateReset : Maybe Posix
    , xPollInterval : Int
    }


type alias GitHubError =
    { status : Int
    }


type alias GitHubEventsChunk =
    GitHubResponse (List GitHubEvent)


type GitHubEventSource
    = GitHubEventSourceDefault
    | GitHubEventSourceUser String
    | GitHubEventSourceOrganisation String
    | GitHubEventSourceRepository String String


type alias GitHubEvent =
    { id : String
    , eventType : String
    , actor : GitHubEventActor
    , repo : GitHubRepoLink
    , payload : GitHubEventPayload
    , created_at : Posix
    }


type alias GitHubEventActor =
    { display_login : String
    , avatar_url : String
    }


type alias GitHubRepoLink =
    { name : String
    , url : String
    }


type GitHubEventPayload
    = GitHubPullRequestEvent GitHubPullRequestEventPayload
    | GitHubReleaseEvent GitHubReleaseEventPayload
    | GitHubOtherEventPayload


type alias GitHubPullRequestEventPayload =
    { action : String
    , pull_request : GitHubPullRequestLink
    }


type alias GitHubPullRequestLink =
    { url : String
    , id : Int
    }


type alias GitHubReleaseEventPayload =
    { action : String
    , release : GitHubReleaseLink
    }


type alias GitHubReleaseLink =
    { url : String
    , tag_name : String
    }


type alias GitHubUserInfo =
    { login : String
    , avatar_url : Url
    , url : Url
    , html_url : Url
    , organizations_url : Url
    , repos_url : Url
    , events_url : Url
    , received_events_url : Url
    , type_ : String
    , name : String
    , company : String
    , location : String
    , email : String
    , public_repos : Int
    , public_gists : Int
    , followers : Int
    , following : Int
    }
