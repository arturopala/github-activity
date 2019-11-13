port module Ports exposing (logError, storeToken)


port storeToken : String -> Cmd msg


port logError : String -> Cmd msg
