module EventStream.Model exposing (..)

import Http exposing (Error)
import Github.Model exposing (..)
import Monocle.Lens exposing (Lens, tuple3)


type alias Model =
    { source : GithubEventSource
    , events : List GithubEvent
    , interval : Int
    , etag : String
    , error : Maybe Http.Error
    }


defaultEventSource : GithubEventSource
defaultEventSource =
    GithubUser "hmrc"


sourceLens : Lens Model GithubEventSource
sourceLens =
    Lens .source (\b a -> { a | source = b })


eventsLens : Lens Model (List GithubEvent)
eventsLens =
    Lens .events (\b a -> { a | events = b })


intervalLens : Lens Model Int
intervalLens =
    Lens .interval (\b a -> { a | interval = b })


etagLens : Lens Model String
etagLens =
    Lens .etag (\b a -> { a | etag = b })


errorLens : Lens Model (Maybe Http.Error)
errorLens =
    Lens .error (\b a -> { a | error = b })