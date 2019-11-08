module GitHub.Message exposing (Msg(..))

import GitHub.Model exposing (GitHubEvent, GitHubResponse, GitHubUserInfo)
import Http


type Msg
    = GotEventsChunk (Result Http.Error (GitHubResponse (List GitHubEvent)))
    | GotUserInfo (Result Http.Error (GitHubResponse GitHubUserInfo))
