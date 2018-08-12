module Model exposing (..)

import Monocle.Lens exposing (Lens, tuple3)
import Routing exposing (Route(..))
import EventStream.Model as EventStream exposing (Model)
import EventStream.Model exposing (defaultEventSource)

type alias Model =
    { route : Route
    , eventStream : EventStream.Model
    , authentication: Authentication
    }


type Authentication = Unauthenticated
    | Token String


eventStreamLens : Lens Model EventStream.Model
eventStreamLens =
    Lens .eventStream (\b a -> { a | eventStream = b })


routeLens : Lens Model Route
routeLens =
    Lens .route (\b a -> { a | route = b })
