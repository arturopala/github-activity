module GitHub.Message exposing (Msg(..))

import GitHub.Model exposing (GitHubEventsChunk, GitHubUserInfo)
import Http


type Msg
    = GotEventsChunk (Result Http.Error GitHubEventsChunk)
    | GotUserInfo (Result Http.Error GitHubUserInfo)
