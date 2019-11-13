module Timeline.Model exposing (Model, activeLens, eventsLens, initialTimeline)

import GitHub.Model exposing (GitHubEvent)
import Monocle.Lens exposing (Lens)


type alias Model =
    { events : List GitHubEvent
    , active : Bool
    }


initialTimeline : Model
initialTimeline =
    { events = []
    , active = True
    }


eventsLens : Lens Model (List GitHubEvent)
eventsLens =
    Lens .events (\b a -> { a | events = b })


activeLens : Lens Model Bool
activeLens =
    Lens .active (\b a -> { a | active = b })
