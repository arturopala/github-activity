module Routing exposing (Route(..), matchers, modifyUrlGivenSource, parseLocation)

import GitHub.Model exposing (GitHubEventSource(..))
import Url exposing (Url)
import Url.Parser exposing (..)
import Url.Parser.Query as Query


type Route
    = EventsRoute GitHubEventSource
    | StartRoute
    | OAuthCode String
    | RouteNotFound


normalize : Url -> Url
normalize url =
    let
        path2 =
            url.fragment |> Maybe.withDefault ""

        fragment2 =
            if url.path == "" then
                Nothing

            else
                Just url.path
    in
    { url
        | protocol = url.protocol
        , host = url.host
        , port_ = url.port_
        , path = path2
        , query = url.query
        , fragment = fragment2
    }


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ top <?> Query.string "code" |> map (\c -> c |> Maybe.map OAuthCode |> Maybe.withDefault StartRoute)
        , s "events" </> s "users" </> string |> map GitHubEventSourceUser |> map EventsRoute
        , s "events" |> map GitHubEventSourceDefault |> map EventsRoute
        ]


parseLocation : Url -> Route
parseLocation location =
    parse matchers (normalize location)
        |> Maybe.withDefault RouteNotFound


modifyUrlGivenSource : Url -> GitHubEventSource -> Url
modifyUrlGivenSource url source =
    case source of
        GitHubEventSourceDefault ->
            { url | fragment = Just "events", query = Nothing }

        GitHubEventSourceUser user ->
            { url | fragment = Just ("events/users/" ++ user), query = Nothing }
