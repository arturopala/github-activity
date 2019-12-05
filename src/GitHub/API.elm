module GitHub.API exposing (Endpoint, searchUsersByLogin)

import GitHub.Authorization exposing (Authorization)
import GitHub.Decode
import GitHub.Handlers exposing (Endpoint2, Handlers, httpGet)
import GitHub.Model exposing (GitHubSearchResult, GitHubUserRef)
import Url exposing (Url)


type Endpoint
    = EventsEndpoint
    | EventsNextPageEndpoint
    | UserSearchEndpoint
    | CurrentUserEndpoint
    | CurrentUserOrganisationsEndpoint


githubApiUrl : Url
githubApiUrl =
    Url Url.Https "api.github.com" Nothing "" Nothing Nothing


searchUsersByLogin : Handlers Endpoint String (GitHubSearchResult GitHubUserRef) msg -> String -> Authorization -> Cmd msg
searchUsersByLogin handlers login auth =
    searchUsers handlers (login ++ "+in:login") auth


searchUsers : Handlers Endpoint String (GitHubSearchResult GitHubUserRef) msg -> String -> Authorization -> Cmd msg
searchUsers handlers query authorization =
    httpGet
        { id = UserSearchEndpoint
        , param = query
        , decoder = GitHub.Decode.decodeUserSearchResult
        , url = { githubApiUrl | path = "/search/users", query = Just ("q=" ++ query) }
        }
        ""
        (asAuthorization authorization)
        handlers


asAuthorization : GitHub.Authorization.Authorization -> GitHub.Handlers.Authorization
asAuthorization authorization =
    case authorization of
        GitHub.Authorization.Unauthorized ->
            GitHub.Handlers.None

        GitHub.Authorization.Token token scope ->
            GitHub.Handlers.Token "token" token
