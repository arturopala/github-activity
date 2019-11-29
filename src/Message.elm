module Message exposing (Msg(..), cacheResponseDecoder)

import Browser exposing (UrlRequest)
import EventStream.Message
import GitHub.API3Request
import GitHub.Endpoint as Endpoint exposing (Endpoint)
import GitHub.Model
import GitHub.OAuth
import Homepage.Message
import Http
import Json.Decode
import Json.Decode.Pipeline
import Time exposing (Zone)
import Timeline.Message
import Url exposing (Url)
import Util


type Msg
    = AuthorizeUserCommand (Cmd Msg)
    | ChangeEventSourceCommand GitHub.Model.GitHubEventSource
    | ChangeUrlCommand UrlRequest
    | ExchangeCodeForTokenCommand String
    | NavigateCommand (Maybe String) (Maybe String)
    | CacheRequest Endpoint
    | CacheResponse Endpoint String Http.Metadata
    | SignOutCommand
    | FullScreenSwitchEvent Bool
    | GotTimeZoneEvent Zone
    | GotTokenEvent GitHub.OAuth.Msg
    | GotUserEvent GitHub.Model.GitHubUser
    | GotUserOrganisationsEvent (List GitHub.Model.GitHubOrganisation)
    | UrlChangedEvent Url
    | EventStreamMsg EventStream.Message.Msg
    | HomepageMsg Homepage.Message.Msg
    | TimelineMsg Timeline.Message.Msg
    | GitHubMsg GitHub.API3Request.GitHubResponse
    | NoOp


cacheResponseDecoder : Json.Decode.Decoder Msg
cacheResponseDecoder =
    Json.Decode.succeed CacheResponse
        |> Json.Decode.Pipeline.required "endpoint" decodeEndpoint
        |> Json.Decode.Pipeline.required "body" Json.Decode.string
        |> Json.Decode.Pipeline.required "metadata"
            (Json.Decode.succeed Http.Metadata
                |> Json.Decode.Pipeline.required "url" Json.Decode.string
                |> Json.Decode.Pipeline.required "statusCode" Json.Decode.int
                |> Json.Decode.Pipeline.required "statusText" Json.Decode.string
                |> Json.Decode.Pipeline.required "headers" (Json.Decode.dict Json.Decode.string)
            )


decodeEndpoint : Json.Decode.Decoder Endpoint
decodeEndpoint =
    Util.decodeUrl |> Json.Decode.map Endpoint.parse
