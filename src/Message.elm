module Message exposing (..)

import Http
import Model exposing (GithubEvent)


type Msg
    = NoOp
    | NewEvents (Result Http.Error (List GithubEvent))
