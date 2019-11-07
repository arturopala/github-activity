module Github.APIv3 exposing (readGithubEvents, readGithubEventsNextPage)

import Dict exposing (Dict)
import Github.Decode exposing (decodeEvents)
import Github.Message exposing (Msg(..))
import Github.Model exposing (..)
import Http
import Json.Decode exposing (decodeString, errorToString)


githubApiUrl : String
githubApiUrl =
    "https://api.github.com"


readGithubEvents : GithubEventSource -> GithubContext -> Cmd Msg
readGithubEvents source context =
    case source of
        None ->
            Cmd.none

        GithubUser user ->
            getEventsWithIntervalRequest (githubApiUrl ++ "/users/" ++ user ++ "/events") context


readGithubEventsNextPage : String -> GithubContext -> Cmd Msg
readGithubEventsNextPage url context =
    getEventsWithIntervalRequest url context


getEventsWithIntervalRequest : String -> GithubContext -> Cmd Msg
getEventsWithIntervalRequest url context =
    let
        headers =
            [ Http.header "If-None-Match" context.etag ]
                ++ (context.token
                        |> Maybe.map (\t -> [ Http.header "Authorization" ("token " ++ t) ])
                        |> Maybe.withDefault []
                   )
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectStringResponse GotEvents getEventsResponse
        , timeout = Nothing
        , tracker = Nothing
        }


getEventsResponse : Http.Response String -> Result Http.Error GithubEventsResponse
getEventsResponse response =
    case response of
        Http.GoodStatus_ metadata body ->
            decodeString decodeEvents body
                |> Result.map
                    (\events ->
                        GithubEventsResponse events
                            (getPollInterval metadata.headers)
                            (getETag metadata.headers)
                            (getLinks metadata.headers)
                    )
                |> Result.mapError (\e -> Http.BadBody (errorToString e))

        Http.BadUrl_ url ->
            Err (Http.BadUrl ("Bad URL " ++ url))

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError

        Http.BadStatus_ metadata body ->
            Err (Http.BadStatus metadata.statusCode)


getPollInterval : Dict String String -> Int
getPollInterval headers =
    headers
        |> Dict.get "x-poll-interval"
        |> Maybe.andThen String.toInt
        |> Maybe.withDefault 120


getETag : Dict String String -> String
getETag headers =
    headers
        |> Dict.get "etag"
        |> Maybe.withDefault ""


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
