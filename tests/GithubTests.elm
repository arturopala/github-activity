module GithubTests exposing (..)

import Test exposing (..)
import Expect
import String
import Github
import Json.Decode exposing (decodeString)
import Model


all : Test
all =
    describe "A Github api decoders"
        [ describe ".decodeRepo should"
            [ test "decode valid repo json" <|
                \() ->
                    Expect.equal
                        (decodeString Github.decodeRepo
                            """{
                                "name":"Artur",
                                "url":"http://foo.org",
                                "foo":"bar"
                            }"""
                        )
                        (Ok (Model.GithubRepo "Artur" "http://foo.org"))
            , test "not decode invalid repo json" <|
                \() ->
                    Expect.err
                        (decodeString Github.decodeRepo
                            """{
                                "neme":"Artur",
                                "Url":"http://foo.org",
                                "foo":"bar"
                            }"""
                        )
            ]
        , describe ".decodeActor should"
            [ test "decode valid actor json" <|
                \() ->
                    Expect.equal
                        (decodeString Github.decodeActor
                            """{
                                "display_login":"foobar",
                                "avatar_url":"http://foo.org",
                                "foo":"bar"
                            }"""
                        )
                        (Ok (Model.GithubActor "foobar" "http://foo.org"))
            , test "not decode invalid actor json" <|
                \() ->
                    Expect.err
                        (decodeString Github.decodeActor
                            """{
                                "login":"foo",
                                "avatar":"http://foo.org",
                                "foo":"bar"
                            }"""
                        )
            ]
        ]
