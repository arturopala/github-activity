module EventStream.Model exposing (Model, contextEtagLens, contextTokenOpt, defaultEventSource, errorLens, etagLens, eventsLens, initialEventStream, intervalLens, sourceLens, tokenOpt)

import Github.Model exposing (..)
import Http exposing (Error)
import Monocle.Lens as Lens exposing (..)
import Monocle.Optional as Optional exposing (..)


type alias Model =
    { source : GithubEventSource
    , events : List GithubEvent
    , interval : Int
    , context : GithubContext
    , error : Maybe Http.Error
    }


initialEventStream : Model
initialEventStream =
    { source = None
    , events = []
    , interval = 60
    , context = GithubContext "" Nothing
    , error = Nothing
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


contextLens : Lens Model GithubContext
contextLens =
    Lens .context (\b a -> { a | context = b })


etagLens : Lens GithubContext String
etagLens =
    Lens .etag (\b a -> { a | etag = b })


tokenOpt : Optional GithubContext String
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
