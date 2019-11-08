module EventStream.Model exposing (Model, contextEtagLens, contextTokenOpt, defaultEventSource, errorLens, etagLens, eventsLens, initialEventStream, intervalLens, sourceLens, tokenOpt)

import GitHub.Model exposing (..)
import Http exposing (Error)
import Monocle.Lens as Lens exposing (..)
import Monocle.Optional as Optional exposing (..)


type alias Model =
    { source : GitHubEventSource
    , events : List GitHubEvent
    , interval : Int
    , context : GitHubContext
    , error : Maybe Http.Error
    }


initialEventStream : Model
initialEventStream =
    { source = None
    , events = []
    , interval = 60
    , context = GitHubContext "" Nothing
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


contextLens : Lens Model GitHubContext
contextLens =
    Lens .context (\b a -> { a | context = b })


etagLens : Lens GitHubContext String
etagLens =
    Lens .etag (\b a -> { a | etag = b })


tokenOpt : Optional GitHubContext String
tokenOpt =
    Optional .token (\b a -> { a | token = Just b })


contextEtagLens : Lens Model String
contextEtagLens =
    Lens.compose contextLens etagLens


contextTokenOpt : Optional Model String
contextTokenOpt =
    Optional.compose (fromLens contextLens) tokenOpt


errorLens : Lens Model (Maybe Http.Error)
errorLens =
    Lens .error (\b a -> { a | error = b })
