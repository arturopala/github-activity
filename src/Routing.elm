module Routing exposing (Route(..), eventsSourceUrl, matchers, parseLocation, rootUrl)

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
            url.fragment |> Maybe.map (\f -> url.path ++ f) |> Maybe.withDefault url.path
    in
    { url
        | protocol = url.protocol
        , host = url.host
        , port_ = url.port_
        , path = path2
        , query = url.query
        , fragment = Nothing
    }


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ top <?> Query.string "code" |> map (\c -> c |> Maybe.map OAuthCode |> Maybe.withDefault StartRoute)
        , s "events" </> s "users" </> string |> map GitHubUser |> map EventsRoute
        ]


parseLocation : Url -> Route
parseLocation location =
    parse matchers (normalize location)
        |> Maybe.withDefault RouteNotFound


rootUrl : String
rootUrl =
    "/"


eventsSourceUrl : GitHubEventSource -> String
eventsSourceUrl source =
    case source of
        None ->
            rootUrl

        GitHubUser user ->
            "#events/users/" ++ user
