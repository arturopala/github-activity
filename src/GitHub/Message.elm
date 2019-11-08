module GitHub.Message exposing (Msg(..))

import GitHub.Model exposing (GitHubEventsResponse)
import Http


type Msg
    = GotEvents (Result Http.Error GitHubEventsResponse)
