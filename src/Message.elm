module Message exposing (Msg(..))

import Browser exposing (UrlRequest)
import EventStream.Message
import GitHub.Message
import GitHub.OAuthProxy
import Url exposing (Url)


type Msg
    = OnUrlChangeMsg Url
    | OnUrlRequestMsg UrlRequest
    | LoginMsg GitHub.OAuthProxy.Msg
    | TimelineMsg EventStream.Message.Msg
    | UserMsg GitHub.Message.Msg
