port module Ports exposing (logError, storeState)


port storeState : String -> Cmd msg


port logError : String -> Cmd msg
