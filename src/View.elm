module View exposing (sourceLabel)

import GitHub.Model exposing (GitHubEventSource)


sourceLabel : GitHubEventSource -> String
sourceLabel source =
    case source of
        GitHub.Model.GitHubEventSourceDefault ->
            "all public github"

        GitHub.Model.GitHubEventSourceUser user ->
            "user " ++ user

        GitHub.Model.GitHubEventSourceOrganisation org ->
            org

        GitHub.Model.GitHubEventSourceRepository owner repo ->
            owner ++ "/" ++ repo
