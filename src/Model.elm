module Model exposing (..)

import Http
import Time.DateTime as DateTime


type alias Model =
    { route : Route
    , eventStream : GithubEventStream
    }


type Route
    = EventsRoute GithubEventSource
    | NotFoundRoute


type alias GithubEventStream =
    { source : GithubEventSource
    , events : List GithubEvent
    , interval : Int
    , etag : String
    , error : Maybe Http.Error
    }


type alias GithubEventsResponse =
    { events : List GithubEvent
    , interval : Int
    , etag : String
    }


type GithubEventSource
    = GithubUser String


type alias GithubEvent =
    { id : String
    , eventType : String
    , actor : GithubActor
    , repo : GithubRepo
    , payload : GithubEventPayload
    , created_at : DateTime.DateTime
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
