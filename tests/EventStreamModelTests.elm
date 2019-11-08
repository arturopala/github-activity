module EventStreamModelTests exposing (all)

import EventStream.Model exposing (..)
import Expect
import GitHub.Model exposing (GitHubContext)
import Test exposing (..)


eventStream : Model
eventStream =
    initialEventStream


all : Test
all =
    describe "An EventStream model"
        [ describe "should have lens"
            [ test "to set token value in a context" <|
                \() ->
                    Expect.equal
                        (contextTokenOpt.set "foo" eventStream)
                        { eventStream | context = GitHubContext "" (Just "foo") }
            ]
        ]
