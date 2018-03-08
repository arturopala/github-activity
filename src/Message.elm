module Message exposing (..)

import Http
import Model exposing (GithubEventsResponse)
import Navigation exposing (Location)


type Msg
    = NoOp
    | ReadEvents
    | GotEvents (Result Http.Error GithubEventsResponse)
    | OnLocationChange Location
