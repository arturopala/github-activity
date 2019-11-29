module View exposing (sourceName)

import GitHub.Model exposing (GitHubEventSource)


sourceName : GitHubEventSource -> String
sourceName source =
    case source of
        GitHub.Model.GitHubEventSourceDefault ->
            "all public github"

        GitHub.Model.GitHubEventSourceUser user ->
            "user " ++ user

        GitHub.Model.GitHubEventSourceOrganisation org ->
            org

        GitHub.Model.GitHubEventSourceRepository owner repo ->
            owner ++ "/" ++ repo

        GitHub.Model.GitHubEventSourceRepositoryById id ->
            "repo: " ++ id
