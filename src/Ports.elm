port module Ports exposing (listenToCache, logError, onFullScreenChange, orderFromCache, putToCache, storeState)

import Json.Encode as Encode


port storeState : String -> Cmd msg


port logError : String -> Cmd msg


port onFullScreenChange : (Bool -> msg) -> Sub msg


port putToCache : Encode.Value -> Cmd msg


port orderFromCache : Encode.Value -> Cmd msg


port listenToCache : (Encode.Value -> msg) -> Sub msg
