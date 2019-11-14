module GitHubPushEventPayloadTests exposing (all)

import Expect
import GitHub.Decode
import Json.Decode exposing (decodeString, errorToString)
import Test exposing (..)
import TestUtil exposing (expectOk, having)


all : Test
all =
    describe "decodePushEventPayload should"
        [ test "decode valid PushEvent json" <|
            \() ->
                let
                    underTest =
                        decodeString GitHub.Decode.decodePushEventPayload
                            """{
                                  "before": "a984efd5c4245e1b08cf874ffc2363ea216d81b1",
                                  "commits": [
                                      {
                                          "author": {
                                              "email": "250927+arturopala@users.noreply.github.com",
                                              "name": "Artur Opala"
                                          },
                                          "distinct": true,
                                          "message": "add GitHub user info model",
                                          "sha": "f593d9ff4f78e835f1818fc36afe83bcf9a09140",
                                          "url": "https://api.github.com/repos/arturopala/github-activity/commits/f593d9ff4f78e835f1818fc36afe83bcf9a09140"
                                      }
                                  ],
                                  "distinct_size": 1,
                                  "head": "f593d9ff4f78e835f1818fc36afe83bcf9a09140",
                                  "push_id": 4250207604,
                                  "ref": "refs/heads/master",
                                  "size": 1
                              }"""
                in
                underTest
                    |> Expect.all
                        [ expectOk errorToString
                            [ having .before (Expect.equal "a984efd5c4245e1b08cf874ffc2363ea216d81b1")
                            , having .ref (Expect.equal "refs/heads/master")
                            , having .size (Expect.equal 1)
                            ]
                        ]
        ]
