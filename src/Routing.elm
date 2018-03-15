module Routing exposing (..)

import Navigation exposing (Location)
import Main.Model exposing (Route(..))
import Github.Model exposing (GithubEventSource(..))
import UrlParser exposing (..)


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ top |> map (GithubUser "hmrc") |> map EventsRoute
        , s "events" </> s "users" </> string |> map GithubUser |> map EventsRoute
        ]


parseLocation : Location -> Route
parseLocation location =
    case (parseHash matchers location) of
        Just route ->
            route

        Nothing ->
            NotFoundRoute


eventsSourceUrl : GithubEventSource -> String
eventsSourceUrl source =
    case source of
        GithubUser user ->
            "#events/users/" ++ user
