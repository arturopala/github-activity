module GithubTests exposing (all)

import Expect
import Github.Decode
import Github.Model
import Json.Decode exposing (decodeString)
import Test exposing (..)


all : Test
all =
    describe "A Github api decoders"
        [ describe ".decodeRepo should"
            [ test "decode valid repo json" <|
                \() ->
                    Expect.equal
                        (decodeString Github.Decode.decodeRepo
                            """{
                                "name":"Artur",
                                "url":"http://foo.org",
                                "foo":"bar"
                            }"""
                        )
                        (Ok (Github.Model.GithubRepo "Artur" "http://foo.org"))
            , test "not decode invalid repo json" <|
                \() ->
                    Expect.err
                        (decodeString Github.Decode.decodeRepo
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
                        (decodeString Github.Decode.decodeActor
                            """{
                                "display_login":"foobar",
                                "avatar_url":"http://foo.org",
                                "foo":"bar"
                            }"""
                        )
                        (Ok (Github.Model.GithubActor "foobar" "http://foo.org"))
            , test "not decode invalid actor json" <|
                \() ->
                    Expect.err
                        (decodeString Github.Decode.decodeActor
                            """{
                                "login":"foo",
                                "avatar":"http://foo.org",
                                "foo":"bar"
                            }"""
                        )
            ]
        ]
