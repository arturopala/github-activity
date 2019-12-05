module Cache exposing (cacheItemDecoder, encodeCacheItem)

import GitHub.Endpoint as Endpoint exposing (Endpoint)
import Http
import Json.Decode
import Json.Decode.Pipeline
import Json.Encode
import Message exposing (Msg)
import Time


encodeCacheItem : Endpoint -> String -> Http.Metadata -> Time.Posix -> Json.Decode.Value
encodeCacheItem endpoint body metadata timestamp =
    Json.Encode.object
        [ ( "endpoint", endpoint |> Endpoint.toJson )
        , ( "body", Json.Encode.string body )
        , ( "metadata", encodeMetadata metadata )
        , ( "timestamp", Json.Encode.int (Time.posixToMillis timestamp) )
        ]


encodeMetadata : Http.Metadata -> Json.Encode.Value
encodeMetadata metadata =
    Json.Encode.object
        [ ( "url", Json.Encode.string metadata.url )
        , ( "statusCode", Json.Encode.int metadata.statusCode )
        , ( "statusText", Json.Encode.string metadata.statusText )
        , ( "headers", Json.Encode.dict identity Json.Encode.string metadata.headers )
        ]


cacheItemDecoder : Json.Decode.Decoder Msg
cacheItemDecoder =
    Json.Decode.oneOf
        [ Json.Decode.succeed Message.GotCacheResponse
            |> Json.Decode.Pipeline.required "endpoint" Endpoint.fromJson
            |> Json.Decode.Pipeline.required "body" Json.Decode.string
            |> Json.Decode.Pipeline.required "metadata"
                (Json.Decode.succeed Http.Metadata
                    |> Json.Decode.Pipeline.required "url" Json.Decode.string
                    |> Json.Decode.Pipeline.required "statusCode" Json.Decode.int
                    |> Json.Decode.Pipeline.required "statusText" Json.Decode.string
                    |> Json.Decode.Pipeline.required "headers" (Json.Decode.dict Json.Decode.string)
                )
            |> Json.Decode.Pipeline.required "timestamp" (Json.Decode.int |> Json.Decode.map Time.millisToPosix)
        , Json.Decode.succeed Message.GotCacheItemNotFound
            |> Json.Decode.Pipeline.required "endpoint" Endpoint.fromJson
        ]
