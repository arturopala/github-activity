module GitHub.API3Response exposing (onSuccess, processResponse)

import Components.UserSearch
import Dict exposing (Dict)
import EventStream.Message
import GitHub.Decode exposing (decodeEvents, decodeOrganisation, decodeUser, decodeUserSearchResult)
import GitHub.Endpoint exposing (Endpoint(..))
import GitHub.Model exposing (GitHubApiLimits, GitHubFailure, GitHubResult, GitHubSuccess)
import Homepage.Message
import Http
import Json.Decode
import Message exposing (Msg)
import Model exposing (Model, etagsLens, limitsLens)
import Ports
import Time exposing (Posix)
import Util exposing (push)


processResponse : Endpoint -> Http.Response String -> Model -> ( Model, Cmd Msg )
processResponse endpoint response model =
    case response of
        Http.GoodStatus_ metadata body ->
            onSuccess endpoint body metadata model

        Http.BadUrl_ url2 ->
            ( model, onBadUrl endpoint (Http.BadUrl url2) url2 )

        Http.Timeout_ ->
            ( model, onTimeout endpoint Http.Timeout )

        Http.NetworkError_ ->
            ( model, onNetworkError endpoint Http.NetworkError )

        Http.BadStatus_ metadata body ->
            let
                limits =
                    parseLimits metadata

                model2 =
                    model
                        |> limitsLens.set limits
            in
            ( model2, onBadStatus endpoint (Http.BadStatus metadata.statusCode) body metadata )


onSuccess : Endpoint -> String -> Http.Metadata -> Model -> ( Model, Cmd Msg )
onSuccess endpoint body metadata model =
    let
        etag =
            getEtag metadata.headers

        limits =
            parseLimits metadata

        links =
            getLinks metadata.headers

        model2 =
            model
                |> limitsLens.set limits
                |> Util.putToDict etagsLens (GitHub.Model.sourceToString model.eventStream.source) etag
    in
    case decodeMessage endpoint body etag links of
        Ok msg ->
            ( model2
            , Cmd.batch [ push msg, push (Message.PutToCacheCommand endpoint body metadata) ]
            )

        Err error ->
            ( model2
            , Cmd.batch
                [ Ports.logError ("JSON decode error: " ++ Json.Decode.errorToString error)
                , case endpoint of
                    EventsEndpoint source ->
                        push (Message.EventStreamMsg <| EventStream.Message.GotEvents source etag links [])

                    EventsNextPageEndpoint source page url ->
                        push (Message.EventStreamMsg <| EventStream.Message.GotEventsNextPage source etag links page [])

                    UserSearchEndpoint query ->
                        push (Message.HomepageMsg <| Homepage.Message.UserSearchMsg <| Components.UserSearch.ResultParsingErrorEvent)

                    _ ->
                        Cmd.none
                ]
            )


decodeMessage : Endpoint -> String -> String -> Dict String String -> Result Json.Decode.Error Msg
decodeMessage endpoint body etag links =
    let
        with decoder wrapper =
            Json.Decode.decodeString decoder body |> Result.map wrapper
    in
    case endpoint of
        EventsEndpoint source ->
            with decodeEvents (Message.EventStreamMsg << EventStream.Message.GotEvents source etag links)

        EventsNextPageEndpoint source page url ->
            with decodeEvents (Message.EventStreamMsg << EventStream.Message.GotEventsNextPage source etag links page)

        UserSearchEndpoint query ->
            with decodeUserSearchResult (Message.HomepageMsg << Homepage.Message.UserSearchMsg << Components.UserSearch.GotUserSearchResult)

        CurrentUserEndpoint ->
            with decodeUser Message.GotUserEvent

        CurrentUserOrganisationsEndpoint ->
            with (Json.Decode.list decodeOrganisation) Message.GotUserOrganisationsEvent


onBadStatus : Endpoint -> Http.Error -> String -> Http.Metadata -> Cmd Msg
onBadStatus endpoint error body metadata =
    case metadata.statusCode of
        304 ->
            case endpoint of
                EventsEndpoint source ->
                    push (Message.EventStreamMsg <| EventStream.Message.NothingNew)

                EventsNextPageEndpoint source page url ->
                    push (Message.EventStreamMsg <| EventStream.Message.NothingNew)

                _ ->
                    Cmd.none

        403 ->
            case endpoint of
                EventsEndpoint source ->
                    push (Message.EventStreamMsg <| EventStream.Message.TemporaryFailure error)

                EventsNextPageEndpoint source page url ->
                    push (Message.EventStreamMsg <| EventStream.Message.TemporaryFailure error)

                _ ->
                    Cmd.none

        404 ->
            case endpoint of
                EventsEndpoint source ->
                    push (Message.EventStreamMsg <| EventStream.Message.PermanentFailure error)

                EventsNextPageEndpoint source page url ->
                    push (Message.EventStreamMsg <| EventStream.Message.PermanentFailure error)

                UserSearchEndpoint query ->
                    push (Message.HomepageMsg <| Homepage.Message.UserSearchMsg <| Components.UserSearch.UsersNotFoundEvent)

                _ ->
                    Cmd.none

        status ->
            case endpoint of
                EventsEndpoint source ->
                    Cmd.batch
                        [ Ports.logError ("Bad status: " ++ String.fromInt status)
                        , push (Message.EventStreamMsg <| EventStream.Message.PermanentFailure error)
                        ]

                EventsNextPageEndpoint source page url ->
                    Cmd.batch
                        [ Ports.logError ("Bad status: " ++ String.fromInt status)
                        , push (Message.EventStreamMsg <| EventStream.Message.PermanentFailure error)
                        ]

                UserSearchEndpoint query ->
                    push (Message.HomepageMsg <| Homepage.Message.UserSearchMsg <| Components.UserSearch.OtherErrorEvent)

                _ ->
                    Cmd.none


onBadUrl : Endpoint -> Http.Error -> String -> Cmd Msg
onBadUrl endpoint error url =
    Cmd.batch
        [ Ports.logError ("Bad URL: " ++ url)
        , case endpoint of
            EventsEndpoint source ->
                push (Message.EventStreamMsg <| EventStream.Message.PermanentFailure error)

            EventsNextPageEndpoint source page url2 ->
                push (Message.EventStreamMsg <| EventStream.Message.PermanentFailure error)

            UserSearchEndpoint query ->
                push (Message.HomepageMsg <| Homepage.Message.UserSearchMsg <| Components.UserSearch.OtherErrorEvent)

            _ ->
                Cmd.none
        ]


onTimeout : Endpoint -> Http.Error -> Cmd Msg
onTimeout endpoint error =
    case endpoint of
        EventsEndpoint source ->
            push (Message.EventStreamMsg <| EventStream.Message.TemporaryFailure error)

        EventsNextPageEndpoint source page url ->
            push (Message.EventStreamMsg <| EventStream.Message.TemporaryFailure error)

        UserSearchEndpoint query ->
            push (Message.HomepageMsg <| Homepage.Message.UserSearchMsg <| Components.UserSearch.ConnectionErrorEvent)

        _ ->
            Cmd.none


onNetworkError : Endpoint -> Http.Error -> Cmd Msg
onNetworkError endpoint error =
    Cmd.batch
        [ push (Message.OrderFromCacheCommand endpoint)
        , case endpoint of
            EventsEndpoint source ->
                push (Message.EventStreamMsg <| EventStream.Message.TemporaryFailure error)

            EventsNextPageEndpoint source page url ->
                push (Message.EventStreamMsg <| EventStream.Message.TemporaryFailure error)

            UserSearchEndpoint query ->
                push (Message.HomepageMsg <| Homepage.Message.UserSearchMsg <| Components.UserSearch.ConnectionErrorEvent)

            _ ->
                Cmd.none
        ]


parseLimits : Http.Metadata -> GitHubApiLimits
parseLimits metadata =
    GitHubApiLimits (getHeaderAsInt "X-RateLimit-Limit" metadata.headers 60)
        (getHeaderAsInt "X-RateLimit-Remaining" metadata.headers 60)
        (getHeaderAsPosix "X-RateLimit-Reset" metadata.headers)
        (getHeaderAsInt "X-Poll-Interval" metadata.headers 120)


getEtag : Dict String String -> String
getEtag headers =
    let
        etag =
            getHeaderAsString "ETag" headers ""
    in
    if String.startsWith "W/" etag then
        String.dropLeft 2 etag

    else
        etag


getHeaderAsString : String -> Dict String String -> String -> String
getHeaderAsString name headers default =
    headers
        |> Dict.get (String.toLower name)
        |> Maybe.withDefault default


getHeaderAsInt : String -> Dict String String -> Int -> Int
getHeaderAsInt name headers default =
    headers
        |> Dict.get (String.toLower name)
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault default


getHeaderAsPosix : String -> Dict String String -> Maybe Posix
getHeaderAsPosix name headers =
    headers
        |> Dict.get (String.toLower name)
        |> Maybe.andThen String.toInt
        |> Maybe.map (\i -> i * 1000)
        |> Maybe.map Time.millisToPosix


getLinks : Dict String String -> Dict String String
getLinks headers =
    headers
        |> Dict.get "link"
        |> Maybe.withDefault ""
        |> String.split ","
        |> List.map (String.split ";")
        |> List.map
            (\s ->
                ( s |> List.head |> Maybe.withDefault "<>" |> String.trim |> String.slice 1 -1
                , s |> List.tail |> Maybe.andThen List.head |> Maybe.withDefault "rel=\"link\"" |> String.trim |> String.slice 5 -1
                )
            )
        |> List.map (\t -> ( Tuple.second t, Tuple.first t ))
        |> Dict.fromList
