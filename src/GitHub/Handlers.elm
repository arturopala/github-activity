module GitHub.Handlers exposing (Authorization(..), Endpoint2, Handlers, emptyHandlers, httpGet, map)

import Http
import Json.Decode
import Task
import Time
import Url exposing (Url)


type alias Endpoint2 t i o =
    { id : t
    , param : i
    , decoder : Json.Decode.Decoder o
    , url : Url
    }


type alias Handlers t i o msg =
    { onSuccess : Endpoint2 t i o -> o -> Http.Metadata -> Time.Posix -> msg
    , onBadBody : Endpoint2 t i o -> Http.Metadata -> Time.Posix -> msg
    , onBadStatus : Endpoint2 t i o -> String -> Http.Metadata -> Time.Posix -> msg
    , onBadUrl : Endpoint2 t i o -> String -> Time.Posix -> msg
    , onTimeout : Endpoint2 t i o -> Time.Posix -> msg
    , onNetworkError : Endpoint2 t i o -> Time.Posix -> msg
    }


type Authorization
    = None
    | Token String String


httpGet : Endpoint2 t i o -> String -> Authorization -> Handlers t i o msg -> Cmd msg
httpGet endpoint etag authorization handlers =
    let
        headers =
            [ Http.header "If-None-Match" etag ]
                ++ (case authorization of
                        Token name token ->
                            [ Http.header "Authorization" (name ++ " " ++ token) ]

                        None ->
                            []
                   )
    in
    Http.task
        { method = "GET"
        , headers = headers
        , url = Url.toString <| endpoint.url
        , body = Http.emptyBody
        , resolver = Http.stringResolver Ok
        , timeout = Just 15000
        }
        |> Task.andThen (\c -> Time.now |> Task.map (\t -> ( c, t )))
        |> Task.map (processResponse endpoint handlers)
        |> Task.perform identity


processResponse : Endpoint2 t i o -> Handlers t i o msg -> ( Http.Response String, Time.Posix ) -> msg
processResponse endpoint handlers response =
    case response of
        ( Http.GoodStatus_ metadata body, timestamp ) ->
            Json.Decode.decodeString endpoint.decoder body
                |> Result.map (\e -> handlers.onSuccess endpoint e metadata timestamp)
                |> Result.withDefault (handlers.onBadBody endpoint metadata timestamp)

        ( Http.BadUrl_ url2, timestamp ) ->
            handlers.onBadUrl endpoint url2 timestamp

        ( Http.Timeout_, timestamp ) ->
            handlers.onTimeout endpoint timestamp

        ( Http.NetworkError_, timestamp ) ->
            handlers.onNetworkError endpoint timestamp

        ( Http.BadStatus_ metadata body, timestamp ) ->
            handlers.onBadStatus endpoint body metadata timestamp


emptyHandlers : msg -> Handlers t i o msg
emptyHandlers msg =
    { onSuccess = \e o m t -> msg
    , onBadBody = \e m t -> msg
    , onBadStatus = \e b m t -> msg
    , onBadUrl = \e u t -> msg
    , onTimeout = \e t -> msg
    , onNetworkError = \e t -> msg
    }


map : (a -> b) -> Handlers t i o a -> Handlers t i o b
map f h =
    { onSuccess = \e o m t -> h.onSuccess e o m t |> f
    , onBadBody = \e m t -> h.onBadBody e m t |> f
    , onBadStatus = \e b m t -> h.onBadStatus e b m t |> f
    , onBadUrl = \e u t -> h.onBadUrl e u t |> f
    , onTimeout = \e t -> h.onTimeout e t |> f
    , onNetworkError = \e t -> h.onNetworkError e t |> f
    }
