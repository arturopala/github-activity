module GitHub.Message exposing (Msg(..))

import GitHub.Model exposing (..)
import Http


type Msg
    = GitHubEventsMsg (Result ( Http.Error, Maybe GitHubApiLimits ) (GitHubResponse (List GitHubEvent)))
    | GitHubUserMsg (Result ( Http.Error, Maybe GitHubApiLimits ) (GitHubResponse GitHubUserInfo))
