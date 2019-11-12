module EventStream.Message exposing (Msg(..))

import GitHub.Message
import GitHub.Model exposing (GitHubEventSource)
import Url exposing (Url)


type Msg
    = ReadEvents
    | ReadEventsNextPage GitHubEventSource Url
    | GitHubResponseEvents GitHub.Message.Msg
    | GitHubResponseEventsNextPage GitHub.Message.Msg
