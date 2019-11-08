module Message exposing (Msg(..))

import Browser exposing (UrlRequest)
import EventStream.Message exposing (Msg(..))
import GitHub.OAuthProxy exposing (Msg(..))
import Url exposing (Url)


type Msg
    = NoOp
    | OnUrlChange Url
    | OnUrlRequest UrlRequest
    | ShowTimeline EventStream.Message.Msg
    | Authorized GitHub.OAuthProxy.Msg
