module GitHub.Endpoint exposing (Endpoint(..), githubApiUrl, matchers, parse, toUrl)

import GitHub.Model exposing (GitHubEventSource)
import Url exposing (Url)
import Url.Parser exposing ((</>), (<?>), Parser, map, oneOf, s, string)
import Url.Parser.Query as Query


githubApiUrl : Url
githubApiUrl =
    Url Url.Https "api.github.com" Nothing "" Nothing Nothing


type Endpoint
    = EventsEndpoint GitHubEventSource
    | EventsNextPageEndpoint GitHubEventSource (Maybe Int)
    | UserSearchEndpoint (Maybe String)
    | CurrentUserEndpoint
    | CurrentUserOrganisationsEndpoint
    | Unresolved Url


matchers : Parser (Endpoint -> a) a
matchers =
    oneOf
        [ s "user" </> string </> s "events" <?> Query.int "page" |> map (\u p -> EventsNextPageEndpoint (GitHub.Model.GitHubEventSourceUser u) p)
        , s "users" </> string </> s "events" |> map (EventsEndpoint << GitHub.Model.GitHubEventSourceUser)
        , s "organizations" </> string </> s "events" <?> Query.int "page" |> map (\u p -> EventsNextPageEndpoint (GitHub.Model.GitHubEventSourceOrganisation u) p)
        , s "orgs" </> string </> s "events" |> map (EventsEndpoint << GitHub.Model.GitHubEventSourceOrganisation)
        , s "repositories" </> string </> s "events" <?> Query.int "page" |> map (\i p -> EventsNextPageEndpoint (GitHub.Model.GitHubEventSourceRepositoryById i) p)
        , s "repos" </> string </> string </> s "events" |> map (\o r -> EventsEndpoint <| GitHub.Model.GitHubEventSourceRepository o r)
        , s "events" <?> Query.int "page" |> map (\p -> EventsNextPageEndpoint GitHub.Model.GitHubEventSourceDefault p)
        , s "events" |> map (EventsEndpoint GitHub.Model.GitHubEventSourceDefault)
        , s "search" </> s "users" <?> Query.string "q" |> map UserSearchEndpoint
        , s "user" |> map CurrentUserEndpoint
        , s "user" </> s "orgs" |> map CurrentUserOrganisationsEndpoint
        ]


parse : Url -> Endpoint
parse url =
    Url.Parser.parse matchers url
        |> Maybe.withDefault (Unresolved url)


toUrl : Endpoint -> Url
toUrl endpoint =
    case endpoint of
        EventsEndpoint source ->
            case source of
                GitHub.Model.GitHubEventSourceDefault ->
                    { githubApiUrl | path = "/events" }

                GitHub.Model.GitHubEventSourceUser user ->
                    { githubApiUrl | path = "/users/" ++ user ++ "/events" }

                GitHub.Model.GitHubEventSourceOrganisation org ->
                    { githubApiUrl | path = "/orgs/" ++ org ++ "/events" }

                GitHub.Model.GitHubEventSourceRepository owner repo ->
                    { githubApiUrl | path = "/repos/" ++ owner ++ "/" ++ repo ++ "/events" }

                GitHub.Model.GitHubEventSourceRepositoryById id ->
                    { githubApiUrl | path = "/repositories/" ++ id ++ "/events" }

        EventsNextPageEndpoint source page ->
            let
                query =
                    page
                        |> Maybe.map String.fromInt
                        |> Maybe.map (\p -> "page=" ++ p)
            in
            case source of
                GitHub.Model.GitHubEventSourceDefault ->
                    { githubApiUrl | path = "/events", query = query }

                GitHub.Model.GitHubEventSourceUser user ->
                    { githubApiUrl | path = "/user/" ++ user ++ "/events", query = query }

                GitHub.Model.GitHubEventSourceOrganisation org ->
                    { githubApiUrl | path = "/organizations/" ++ org ++ "/events", query = query }

                GitHub.Model.GitHubEventSourceRepository owner repo ->
                    { githubApiUrl | path = "/repository/" ++ owner ++ "/" ++ repo ++ "/events", query = query }

                GitHub.Model.GitHubEventSourceRepositoryById id ->
                    { githubApiUrl | path = "/repositories/" ++ id ++ "/events", query = query }

        UserSearchEndpoint query ->
            { githubApiUrl | path = "/search/users", query = query |> Maybe.map (\q -> "q=" ++ q) }

        CurrentUserEndpoint ->
            { githubApiUrl | path = "/user" }

        CurrentUserOrganisationsEndpoint ->
            { githubApiUrl | path = "/user/orgs" }

        Unresolved url ->
            url
