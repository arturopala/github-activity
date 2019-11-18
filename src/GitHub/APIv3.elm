module GitHub.APIv3 exposing (readCurrentUserInfo, readCurrentUserOrganisations, readGitHubEvents, readGitHubEventsNextPage, searchUsers, searchUsersByLogin)

import Dict exposing (Dict)
import GitHub.Decode exposing (decodeEvents, decodeOrganisation, decodeUser, decodeUserSearchResult)
import GitHub.Message exposing (Msg(..))
import GitHub.Model exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder, decodeString, errorToString)
import Model exposing (Authorization(..))
import Time exposing (Posix)
import Url exposing (Url)


type alias ResultToMsg a =
    Result ( Http.Error, Maybe GitHubApiLimits ) (GitHubResponse a) -> Msg


githubApiUrl : Url
githubApiUrl =
    Url Url.Https "api.github.com" Nothing "" Nothing Nothing


readGitHubEvents : GitHubEventSource -> String -> Authorization -> Cmd Msg
readGitHubEvents source etag auth =
    case source of
        GitHubEventSourceDefault ->
            httpGet { githubApiUrl | path = "/events" } etag auth GitHubEventsMsg decodeEvents

        GitHubEventSourceUser user ->
            httpGet { githubApiUrl | path = "/users/" ++ user ++ "/events" } etag auth GitHubEventsMsg decodeEvents

        GitHubEventSourceOrganisation org ->
            httpGet { githubApiUrl | path = "/orgs/" ++ org ++ "/events" } etag auth GitHubEventsMsg decodeEvents

        GitHubEventSourceRepository owner repo ->
            httpGet { githubApiUrl | path = "/repos/" ++ owner ++ "/" ++ repo ++ "/events" } etag auth GitHubEventsMsg decodeEvents


readGitHubEventsNextPage : Url -> String -> Authorization -> Cmd Msg
readGitHubEventsNextPage url etag auth =
    httpGet url etag auth GitHubEventsMsg decodeEvents


readCurrentUserInfo : Authorization -> Cmd Msg
readCurrentUserInfo auth =
    httpGet { githubApiUrl | path = "/user" } "" auth GitHubUserMsg decodeUser


readCurrentUserOrganisations : Authorization -> Cmd Msg
readCurrentUserOrganisations auth =
    httpGet { githubApiUrl | path = "/user/orgs" } "" auth GitHubUserOrganisationsMsg (Decode.list decodeOrganisation)


searchUsersByLogin : String -> Authorization -> Cmd Msg
searchUsersByLogin login auth =
    searchUsers (login ++ "+in:login") auth


searchUsers : String -> Authorization -> Cmd Msg
searchUsers query auth =
    httpGet { githubApiUrl | path = "/search/users", query = Just ("q=" ++ query) } "" auth GitHubUserSearchMsg decodeUserSearchResult


httpGet : Url -> String -> Authorization -> ResultToMsg a -> Decoder a -> Cmd Msg
httpGet url etag auth resultToMsg decoder =
    let
        headers =
            [ Http.header "If-None-Match" etag ]
                ++ (case auth of
                        Token token scope ->
                            [ Http.header "Authorization" ("token " ++ token) ]

                        Unauthorized ->
                            []
                   )
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = Url.toString url
        , body = Http.emptyBody
        , expect = Http.expectStringResponse resultToMsg (decodeGitHubResponse decoder)
        , timeout = Nothing
        , tracker = Nothing
        }


decodeGitHubResponse : Decoder a -> Http.Response String -> Result ( Http.Error, Maybe GitHubApiLimits ) (GitHubResponse a)
decodeGitHubResponse decoder response =
    case response of
        Http.GoodStatus_ metadata body ->
            decodeString decoder body
                |> Result.map
                    (\content ->
                        GitHubResponse content
                            (getEtag metadata.headers)
                            (getLinks metadata.headers)
                            (parseLimits metadata)
                    )
                |> Result.mapError (\e -> ( Http.BadBody (errorToString e), Just (parseLimits metadata) ))

        Http.BadUrl_ url ->
            Err ( Http.BadUrl ("Bad URL " ++ url), Nothing )

        Http.Timeout_ ->
            Err ( Http.Timeout, Nothing )

        Http.NetworkError_ ->
            Err ( Http.NetworkError, Nothing )

        Http.BadStatus_ metadata body ->
            let
                limits =
                    parseLimits metadata
            in
            Err ( Http.BadStatus metadata.statusCode, Just limits )


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
