module Homepage.Message exposing (Msg(..))

import Components.UserSearch
import GitHub.Model


type Msg
    = UserSearchMsg Components.UserSearch.Msg
    | SourceSelectedEvent GitHub.Model.GitHubEventSource
    | RemoveSourceCommand GitHub.Model.GitHubEventSource
