module Message exposing (Msg(..))

import Browser exposing (UrlRequest)
import EventStream.Message
import GitHub.Model
import GitHub.OAuthProxy
import Homepage.Message
import Time exposing (Zone)
import Timeline.Message
import Url exposing (Url)


type Msg
    = AuthorizeUserCommand (Cmd Msg)
    | ChangeEventSourceCommand GitHub.Model.GitHubEventSource
    | ChangeUrlCommand UrlRequest
    | NavigateCommand (Maybe String) (Maybe String)
    | SignOutCommand
    | GotTimeZoneEvent Zone
    | GotTokenEvent GitHub.OAuthProxy.Msg
    | ReadUserEvent GitHub.Model.GitHubUser
    | ReadUserOrganisationsEvent (List GitHub.Model.GitHubOrganisation)
    | UrlChangedEvent Url
    | EventStreamMsg EventStream.Message.Msg
    | HomepageMsg Homepage.Message.Msg
    | TimelineMsg Timeline.Message.Msg
    | NoOp
