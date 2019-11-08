module GitHub.Message exposing (Msg(..))

import GitHub.Model exposing (..)
import Http


type Msg
    = GitHubEventsMsg (Result Http.Error (GitHubResponse (List GitHubEvent)))
    | GitHubUserMsg (Result Http.Error (GitHubResponse GitHubUserInfo))
