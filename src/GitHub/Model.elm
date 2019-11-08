module GitHub.Model exposing (GitHubActor, GitHubContext, GitHubEvent, GitHubEventPayload(..), GitHubEventSource(..), GitHubEventsResponse, GitHubPullRequest, GitHubPullRequestEventPayload, GitHubRelease, GitHubReleaseEventPayload, GitHubRepo)

import Dict exposing (Dict)
import Time exposing (Posix)


type alias GitHubContext =
    { etag : String
    , token : Maybe String
    }


type alias GitHubEventsResponse =
    { events : List GitHubEvent
    , interval : Int
    , etag : String
    , links : Dict String String
    }


type GitHubEventSource
    = None
    | GitHubUser String


type alias GitHubEvent =
    { id : String
    , eventType : String
    , actor : GitHubActor
    , repo : GitHubRepo
    , payload : GitHubEventPayload
    , created_at : Posix
    }


type alias GitHubActor =
    { display_login : String
    , avatar_url : String
    }


type alias GitHubRepo =
    { name : String
    , url : String
    }


type GitHubEventPayload
    = GitHubPullRequestEvent GitHubPullRequestEventPayload
    | GitHubReleaseEvent GitHubReleaseEventPayload
    | GitHubOtherEventPayload


type alias GitHubPullRequestEventPayload =
    { action : String
    , pull_request : GitHubPullRequest
    }


type alias GitHubPullRequest =
    { url : String
    , id : Int
    }


type alias GitHubReleaseEventPayload =
    { action : String
    , release : GitHubRelease
    }


type alias GitHubRelease =
    { url : String
    , tag_name : String
    }
