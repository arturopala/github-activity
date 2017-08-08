module Tests exposing (..)

import Test exposing (..)
import GithubTests


all : Test
all =
    concat
        [ GithubTests.all
        ]
