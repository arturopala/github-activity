module Message exposing (Msg(..))

import Browser exposing (UrlRequest)
import EventStream.Message
import GitHub.API3Request
import GitHub.Endpoint exposing (Endpoint)
import GitHub.Model
import GitHub.OAuth
import Homepage.Message
import Http
import Time exposing (Zone)
import Timeline.Message
import Url exposing (Url)


type Msg
    = AuthorizeUserCommand (Cmd Msg)
    | ChangeEventSourceCommand GitHub.Model.GitHubEventSource
    | ChangeUrlCommand UrlRequest
    | ExchangeCodeForTokenCommand String
    | NavigateCommand (Maybe String) (Maybe String)
    | SignOutCommand
    | FullScreenSwitchEvent Bool
    | GotTimeZoneEvent Zone
    | GotTokenEvent GitHub.OAuth.Msg
    | GotUserEvent GitHub.Model.GitHubUser
    | GotUserOrganisationsEvent (List GitHub.Model.GitHubOrganisation)
    | UrlChangedEvent Url
    | PutToCacheCommand Endpoint String Http.Metadata
    | OrderFromCacheCommand Endpoint
    | CacheResponseEvent Endpoint String Http.Metadata
    | EventStreamMsg EventStream.Message.Msg
    | HomepageMsg Homepage.Message.Msg
    | TimelineMsg Timeline.Message.Msg
    | GitHubMsg GitHub.API3Request.GitHubResponse
    | NoOp
