module GitHub.Endpoint exposing (Endpoint(..), fromJson, githubApiUrl, parsePageNumber, toJson, toUrl)

import GitHub.Model exposing (GitHubEventSource)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Url exposing (Url)
import Url.Parser
import Url.Parser.Query as Query
import Util


githubApiUrl : Url
githubApiUrl =
    Url Url.Https "api.github.com" Nothing "" Nothing Nothing


type Endpoint
    = EventsEndpoint GitHubEventSource
    | EventsNextPageEndpoint GitHubEventSource Int Url
    | UserSearchEndpoint String
    | CurrentUserEndpoint
    | CurrentUserOrganisationsEndpoint


toUrl : Endpoint -> Url
toUrl endpoint =
    case endpoint of
        EventsEndpoint source ->
            case source of
                GitHub.Model.GitHubEventSourceDefault ->
                    { githubApiUrl | path = "/events" }

                GitHub.Model.GitHubEventSourceUser user ->
                    { githubApiUrl | path = "/users/" ++ user ++ "/events" }

                GitHub.Model.GitHubEventSourceOrganisation org ->
                    { githubApiUrl | path = "/orgs/" ++ org ++ "/events" }

                GitHub.Model.GitHubEventSourceRepository owner repo ->
                    { githubApiUrl | path = "/repos/" ++ owner ++ "/" ++ repo ++ "/events" }

        EventsNextPageEndpoint source page url ->
            url

        UserSearchEndpoint query ->
            { githubApiUrl | path = "/search/users", query = Just ("q=" ++ query) }

        CurrentUserEndpoint ->
            { githubApiUrl | path = "/user" }

        CurrentUserOrganisationsEndpoint ->
            { githubApiUrl | path = "/user/orgs" }


toJson : Endpoint -> Encode.Value
toJson endpoint =
    case endpoint of
        EventsEndpoint source ->
            Encode.object
                [ ( "events"
                  , Encode.object [ ( "source", GitHub.Model.toJson source ) ]
                  )
                ]

        EventsNextPageEndpoint source page url ->
            Encode.object
                [ ( "eventsNextPage"
                  , Encode.object
                        [ ( "source", GitHub.Model.toJson source )
                        , ( "page", Encode.int page )
                        , ( "url", Encode.string (Url.toString url) )
                        ]
                  )
                ]

        UserSearchEndpoint query ->
            Encode.object
                [ ( "userSearch", Encode.object [ ( "query", Encode.string query ) ] ) ]

        CurrentUserEndpoint ->
            Encode.object
                [ ( "currentUser"
                  , Encode.null
                  )
                ]

        CurrentUserOrganisationsEndpoint ->
            Encode.object
                [ ( "currentUserOrganisations"
                  , Encode.null
                  )
                ]


fromJson : Decode.Decoder Endpoint
fromJson =
    Decode.oneOf
        [ decodeEventsEndpoint
        , decodeEventsNextPageEndpoint
        , decodeUserSearchEndpoint
        , decodeCurrentUserEndpoint
        , decodeCurrentUserOrganisationsEndpoint
        ]


decodeEventsEndpoint =
    Decode.field "events"
        (Decode.succeed EventsEndpoint
            |> required "source" GitHub.Model.fromJson
        )


decodeEventsNextPageEndpoint =
    Decode.field "events"
        (Decode.succeed EventsNextPageEndpoint
            |> required "source" GitHub.Model.fromJson
            |> required "page" Decode.int
            |> required "url" Util.decodeUrl
        )


decodeUserSearchEndpoint =
    Decode.field "userSearch"
        (Decode.succeed UserSearchEndpoint
            |> required "query" Decode.string
        )


decodeCurrentUserEndpoint =
    Decode.field "currentUser" (Decode.succeed CurrentUserEndpoint)


decodeCurrentUserOrganisationsEndpoint =
    Decode.field "currentUserOrganisations" (Decode.succeed CurrentUserOrganisationsEndpoint)


parsePageNumber : Url -> Int
parsePageNumber url =
    Url.Parser.parse (Url.Parser.query (Query.int "page")) url
        |> Maybe.map (\p -> Maybe.withDefault 1 p)
        |> Maybe.withDefault 1
