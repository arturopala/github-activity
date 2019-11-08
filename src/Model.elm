module Model exposing (Authorization(..), Mode(..), Model, eventStreamLens, eventStreamSourceLens, modeLens, routeLens)

import Browser.Navigation exposing (Key)
import EventStream.Model as EventStream exposing (Model, sourceLens)
import GitHub.Model
import Monocle.Lens exposing (Lens, compose)
import Routing exposing (Route(..))


type alias Model =
    { title : String
    , key : Key
    , mode : Mode
    , route : Route
    , eventStream : EventStream.Model
    , authorization : Authorization
    }


type Mode
    = Welcome
    | Timeline


type Authorization
    = Unauthorized
    | Token String


eventStreamLens : Lens Model EventStream.Model
eventStreamLens =
    Lens .eventStream (\b a -> { a | eventStream = b })


modeLens : Lens Model Mode
modeLens =
    Lens .mode (\b a -> { a | mode = b })


routeLens : Lens Model Route
routeLens =
    Lens .route (\b a -> { a | route = b })


eventStreamSourceLens : Lens Model GitHub.Model.GitHubEventSource
eventStreamSourceLens =
    compose eventStreamLens sourceLens
