module GitHubTests exposing (all)

import Expect
import GitHub.Decode
import GitHub.Model
import Json.Decode exposing (decodeString)
import Test exposing (..)


all : Test
all =
    describe "A GitHub api decoders"
        [ describe ".decodeRepo should"
            [ test "decode valid repo json" <|
                \() ->
                    Expect.equal
                        (decodeString GitHub.Decode.decodeRepo
                            """{
                                "name":"Artur",
                                "url":"http://foo.org",
                                "foo":"bar"
                            }"""
                        )
                        (Ok (GitHub.Model.GitHubRepoLink "Artur" "http://foo.org"))
            , test "not decode invalid repo json" <|
                \() ->
                    Expect.err
                        (decodeString GitHub.Decode.decodeRepo
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
                        (decodeString GitHub.Decode.decodeActor
                            """{
                                "display_login":"foobar",
                                "avatar_url":"http://foo.org",
                                "foo":"bar"
                            }"""
                        )
                        (Ok (GitHub.Model.GitHubEventActor "foobar" "http://foo.org"))
            , test "not decode invalid actor json" <|
                \() ->
                    Expect.err
                        (decodeString GitHub.Decode.decodeActor
                            """{
                                "login":"foo",
                                "avatar":"http://foo.org",
                                "foo":"bar"
                            }"""
                        )
            ]
        ]
