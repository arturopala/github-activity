module GitHub.Model exposing (GitHubContext, GitHubEvent, GitHubEventActor, GitHubEventPayload(..), GitHubEventSource(..), GitHubEventsResponse, GitHubPullRequestEventPayload, GitHubPullRequestLink, GitHubReleaseEventPayload, GitHubReleaseLink, GitHubRepoLink)

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
