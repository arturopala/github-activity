module Message exposing (..)

import Http
import Model exposing (GithubEvent)

type alias EventsResponse = 
    { events: List GithubEvent
    , interval: Int
    , etag: String
    }

type Msg
    = NoOp
    | ReadEvents
    | GotEvents (Result Http.Error EventsResponse)
