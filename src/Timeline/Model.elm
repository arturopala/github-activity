module Timeline.Model exposing (Model, eventsLens, initialTimeline)

import GitHub.Model exposing (GitHubEvent)
import Monocle.Lens exposing (Lens)


type alias Model =
    { events : List GitHubEvent
    }


initialTimeline : Model
initialTimeline =
    { events = []
    }


eventsLens : Lens Model (List GitHubEvent)
eventsLens =
    Lens .events (\b a -> { a | events = b })
