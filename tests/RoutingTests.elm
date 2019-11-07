module RoutingTests exposing (all)

import Expect
import Github.Model
import Routing
import Test exposing (..)
import Url


all : Test
all =
    describe "A Routing"
        [ describe "should match location"
            [ test "when /" <|
                \() ->
                    Expect.equal
                        (Url.fromString "https://example.com:3000/"
                            |> Maybe.map Routing.parseLocation
                            |> Maybe.withDefault Routing.RouteNotFound
                        )
                        Routing.StartRoute
            , test "when /?code=XXX" <|
                \() ->
                    Expect.equal
                        (Url.fromString "https://localhost:3000/?code=123abc567ef"
                            |> Maybe.map Routing.parseLocation
                            |> Maybe.withDefault Routing.RouteNotFound
                        )
                        (Routing.OAuthCode "123abc567ef")
            , test "when /#events/users/foo" <|
                \() ->
                    Expect.equal
                        (Url.fromString "https://localhost:3000/#events/users/foo"
                            |> Maybe.map Routing.parseLocation
                            |> Maybe.withDefault Routing.RouteNotFound
                        )
                        (Routing.EventsRoute (Github.Model.GithubUser "foo"))
            ]
        ]
