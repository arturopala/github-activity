module EventStream.Model exposing (Model, errorLens, etagLens, eventsLens, initialEventStream, sourceLens)

import GitHub.Model exposing (..)
import Http exposing (Error)
import Monocle.Lens exposing (..)


type alias Model =
    { source : GitHubEventSource
    , events : List GitHubEvent
    , etag : String
    , error : Maybe Http.Error
    }


initialEventStream : Model
initialEventStream =
    { source = GitHubEventSourceDefault
    , events = []
    , etag = ""
    , error = Nothing
    }


sourceLens : Lens Model GitHubEventSource
sourceLens =
    Lens .source (\b a -> { a | source = b })


eventsLens : Lens Model (List GitHubEvent)
eventsLens =
    Lens .events (\b a -> { a | events = b })


etagLens : Lens Model String
etagLens =
    Lens .etag (\b a -> { a | etag = b })


errorLens : Lens Model (Maybe Http.Error)
errorLens =
    Lens .error (\b a -> { a | error = b })
