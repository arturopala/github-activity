module Github exposing (..)

import Http
import Json.Decode exposing (int, string, float, Decoder, decodeString, list, nullable, map)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Model exposing (..)
import Message exposing (..)
import Time.DateTime as DateTime


getEvents : Cmd Msg
getEvents =
    Http.send NewEvents getEventsRequest


getEventsRequest : Http.Request (List GithubEvent)
getEventsRequest =
    Http.get "https://api.github.com/users/hmrc/events" decodeEvents


decodeEvents : Decoder (List GithubEvent)
decodeEvents =
    list decodeEvent


decodeEvent : Decoder GithubEvent
decodeEvent =
    decode GithubEvent
        |> required "id" string
        |> required "type" string
        |> required "actor" decodeActor
        |> required "repo" decodeRepo
        |> required "payload" decodePayload
        |> required "created_at" decodeDateTime


decodeActor : Decoder GithubActor
decodeActor =
    decode GithubActor
        |> required "display_login" string
        |> required "avatar_url" string


decodeRepo =
    decode GithubRepo
        |> required "name" string
        |> required "url" string


decodePayload =
    decode GithubPayload
        |> optional "size" int 0


decodeDateTime : Decoder DateTime.DateTime
decodeDateTime =
    map (DateTime.fromISO8601 >> Result.withDefault DateTime.epoch) string
