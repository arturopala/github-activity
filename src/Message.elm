module Message exposing (Msg(..))

import Browser exposing (UrlRequest)
import EventStream.Message
import GitHub.Message
import GitHub.Model
import GitHub.OAuthProxy
import Time exposing (Zone)
import Timeline.Message
import Url exposing (Url)


type Msg
    = AuthorizeUserCommand (Cmd Msg)
    | SignOutCommand
    | ChangeUrlCommand UrlRequest
    | ChangeEventSourceCommand GitHub.Model.GitHubEventSource
    | NavigateCommand (Maybe String) (Maybe String)
    | GotGitHubApiResponseEvent GitHub.Message.Msg
    | GotTimeZoneEvent Zone
    | GotTokenEvent GitHub.OAuthProxy.Msg
    | ClockTickEvent
    | UrlChangedEvent Url
    | EventStreamMsg EventStream.Message.Msg
    | TimelineMsg Timeline.Message.Msg
