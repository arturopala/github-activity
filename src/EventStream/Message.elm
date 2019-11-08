module EventStream.Message exposing (Msg(..))

import GitHub.Message


type Msg
    = NoOp
    | ReadEvents
    | ReadEventsNextPage String
    | GitHubResponseEvents GitHub.Message.Msg
    | GitHubResponseEventsNextPage GitHub.Message.Msg
