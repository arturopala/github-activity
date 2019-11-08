module EventStream.Model exposing (Model, defaultEventSource, errorLens, etagLens, eventsLens, initialEventStream, intervalLens, sourceLens)

import GitHub.Model exposing (..)
import Http exposing (Error)
import Monocle.Lens exposing (..)


type alias Model =
    { source : GitHubEventSource
    , events : List GitHubEvent
    , interval : Int
    , etag : String
    , error : Maybe Http.Error
    }


initialEventStream : Model
initialEventStream =
    { source = None
    , events = []
    , interval = 60
    , etag = ""
    , error = Nothing
    }


defaultEventSource : GitHubEventSource
defaultEventSource =
    GitHubUser "hmrc"


sourceLens : Lens Model GitHubEventSource
sourceLens =
    Lens .source (\b a -> { a | source = b })


eventsLens : Lens Model (List GitHubEvent)
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
