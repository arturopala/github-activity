module EventStream.Model exposing (Model, chunksLens, errorLens, eventsLens, initialEventStream, sourceLens)

import GitHub.Model exposing (..)
import Http exposing (Error)
import Monocle.Lens exposing (..)


type alias Model =
    { source : GitHubEventSource
    , events : List GitHubEvent
    , chunks : List GitHubEvent
    , error : Maybe Http.Error
    }


initialEventStream : Model
initialEventStream =
    { source = GitHubEventSourceDefault
    , events = []
    , chunks = []
    , error = Nothing
    }


sourceLens : Lens Model GitHubEventSource
sourceLens =
    Lens .source (\b a -> { a | source = b })


eventsLens : Lens Model (List GitHubEvent)
eventsLens =
    Lens .events (\b a -> { a | events = b })


chunksLens : Lens Model (List GitHubEvent)
chunksLens =
    Lens .chunks (\b a -> { a | chunks = b })


errorLens : Lens Model (Maybe Http.Error)
errorLens =
    Lens .error (\b a -> { a | error = b })
