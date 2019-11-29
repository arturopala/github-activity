port module Ports exposing (cacheRequest, cacheResponse, logError, onFullScreenChange, storeState)

import Json.Encode as Encode


port storeState : String -> Cmd msg


port logError : String -> Cmd msg


port onFullScreenChange : (Bool -> msg) -> Sub msg


port cacheRequest : String -> Cmd msg


port cacheResponse : (Encode.Value -> msg) -> Sub msg
