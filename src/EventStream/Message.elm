module EventStream.Message exposing (Msg(..))

import GitHub.Message
import Url exposing (Url)


type Msg
    = NoOp
    | ReadEvents
    | ReadEventsNextPage Url
    | GitHubResponseEvents GitHub.Message.Msg
    | GitHubResponseEventsNextPage GitHub.Message.Msg
