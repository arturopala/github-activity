module Github.Model exposing (GithubActor, GithubContext, GithubEvent, GithubEventPayload(..), GithubEventSource(..), GithubEventsResponse, GithubPullRequest, GithubPullRequestEventPayload, GithubRelease, GithubReleaseEventPayload, GithubRepo)

import Dict exposing (Dict)
import Time exposing (Posix)


type alias GithubContext =
    { etag : String
    , token : Maybe String
    }


type alias GithubEventsResponse =
    { events : List GithubEvent
    , interval : Int
    , etag : String
    , links : Dict String String
    }


type GithubEventSource
    = None
    | GithubUser String


type alias GithubEvent =
    { id : String
    , eventType : String
    , actor : GithubActor
    , repo : GithubRepo
    , payload : GithubEventPayload
    , created_at : Posix
    }


type alias GithubActor =
    { display_login : String
    , avatar_url : String
    }


type alias GithubRepo =
    { name : String
    , url : String
    }


type GithubEventPayload
    = GithubPullRequestEvent GithubPullRequestEventPayload
    | GithubReleaseEvent GithubReleaseEventPayload
    | GithubOtherEventPayload


type alias GithubPullRequestEventPayload =
    { action : String
    , pull_request : GithubPullRequest
    }


type alias GithubPullRequest =
    { url : String
    , id : Int
    }


type alias GithubReleaseEventPayload =
    { action : String
    , release : GithubRelease
    }


type alias GithubRelease =
    { url : String
    , tag_name : String
    }
