module Tests exposing (..)

import Test exposing (..)
import GithubTests
import GithubPullRequestEventPayloadTests
import GithubReleaseEventPayloadTests


all : Test
all =
    concat
        [ GithubTests.all
        , describe "A Github event payload decoders" 
            [ concat 
                [ GithubPullRequestEventPayloadTests.all
                , GithubReleaseEventPayloadTests.all
            ]]
        ]
