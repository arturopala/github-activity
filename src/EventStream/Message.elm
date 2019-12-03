module EventStream.Message exposing (Msg(..))

import Dict exposing (Dict)
import GitHub.Model exposing (GitHubEvent, GitHubEventSource)
import Http
import Url exposing (Url)


type Msg
    = ReadEvents
    | ReadEventsNextPage GitHubEventSource Url
    | GotEvents GitHubEventSource String (Dict String String) (List GitHubEvent)
    | GotEventsNextPage GitHubEventSource String (Dict String String) Int (List GitHubEvent)
    | NothingNew
    | TemporaryFailure Http.Error
    | PermanentFailure Http.Error
    | ForceFlushChunksAfterTimeout
