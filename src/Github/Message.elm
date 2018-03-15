module Github.Message exposing (..)

import Http
import Github.Model exposing (GithubEventsResponse)


type Msg
    = GotEvents (Result Http.Error GithubEventsResponse)
