port module Ports exposing (logError, onFullScreenChange, storeState)


port storeState : String -> Cmd msg


port logError : String -> Cmd msg


port onFullScreenChange : (Bool -> msg) -> Sub msg
