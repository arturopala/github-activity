module EventStream.Message exposing (Msg(..))

import GitHub.Message
import Url exposing (Url)


type Msg
    = ReadEvents
    | ReadEventsNextPage Url
    | GitHubResponseEvents GitHub.Message.Msg
