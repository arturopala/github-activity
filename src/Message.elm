module Message exposing (Msg(..))

import Browser exposing (UrlRequest)
import EventStream.Message
import GitHub.Message
import GitHub.OAuthProxy
import Timeline.Message
import Url exposing (Url)


type Msg
    = OnUrlChangeMsg Url
    | OnUrlRequestMsg UrlRequest
    | LoginMsg GitHub.OAuthProxy.Msg
    | EventStreamMsg EventStream.Message.Msg
    | TimelineMsg Timeline.Message.Msg
    | UserMsg GitHub.Message.Msg
    | TickMsg
