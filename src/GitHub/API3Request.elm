module GitHub.API3Request exposing (GitHubResponse, readCurrentUserInfo, readCurrentUserOrganisations, readGitHubEvents, readGitHubEventsNextPage, searchUsers, searchUsersByLogin)

import GitHub.Authorization exposing (Authorization(..))
import GitHub.Endpoint as Endpoint exposing (Endpoint(..), parsePageNumber)
import GitHub.Model exposing (..)
import Http
import Url exposing (Url)


type alias GitHubResponse =
    Result Never ( Endpoint, Http.Response String )


readGitHubEvents : GitHubEventSource -> String -> Authorization -> Cmd GitHubResponse
readGitHubEvents source etag auth =
    httpGet (EventsEndpoint source) etag auth


readGitHubEventsNextPage : GitHubEventSource -> Url -> String -> Authorization -> Cmd GitHubResponse
readGitHubEventsNextPage source url etag auth =
    httpGet (EventsNextPageEndpoint source (parsePageNumber url) url) etag auth


readCurrentUserInfo : Authorization -> Cmd GitHubResponse
readCurrentUserInfo auth =
    httpGet CurrentUserEndpoint "" auth


readCurrentUserOrganisations : Authorization -> Cmd GitHubResponse
readCurrentUserOrganisations auth =
    httpGet CurrentUserOrganisationsEndpoint "" auth


searchUsersByLogin : String -> Authorization -> Cmd GitHubResponse
searchUsersByLogin login auth =
    searchUsers (login ++ "+in:login") auth


searchUsers : String -> Authorization -> Cmd GitHubResponse
searchUsers query auth =
    httpGet (UserSearchEndpoint query) "" auth


httpGet : Endpoint -> String -> Authorization -> Cmd GitHubResponse
httpGet endpoint etag auth =
    let
        headers =
            [ Http.header "If-None-Match" etag ]
                ++ (case auth of
                        Token token scope ->
                            [ Http.header "Authorization" ("token " ++ token) ]

                        Unauthorized ->
                            []
                   )
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = Url.toString <| Endpoint.toUrl endpoint
        , body = Http.emptyBody
        , expect = Http.expectStringResponse identity (\r -> Ok ( endpoint, r ))
        , timeout = Just 15000
        , tracker = Nothing
        }
