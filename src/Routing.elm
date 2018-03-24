module Routing exposing (..)

import Navigation exposing (Location)
import UrlParser exposing (..)
import Github.Model exposing (GithubEventSource(..))
import EventStream.Model exposing (defaultEventSource)


type Route
    = EventsRoute GithubEventSource
    | NotFoundRoute


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ top |> map defaultEventSource |> map EventsRoute
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
