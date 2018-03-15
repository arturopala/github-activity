module Main.Message exposing (..)

import Navigation exposing (Location)
import Github.Message


type Msg
    = NoOp
    | ReadEvents
    | GithubResponse Github.Message.Msg
    | OnLocationChange Location
