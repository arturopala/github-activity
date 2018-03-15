module Main.Model exposing (..)

import Http exposing (Error)
import Github.Model exposing (..)
import Monocle.Lens exposing (Lens, tuple3)
import Monocle.Common exposing (..)


defaultUser : String
defaultUser =
    "hmrc"


type alias Model =
    { route : Route
    , eventStream : EventStream
    }


eventStreamLens : Lens Model EventStream
eventStreamLens =
    Lens .eventStream (\b a -> { a | eventStream = b })


routeLens : Lens Model Route
routeLens =
    Lens .route (\b a -> { a | route = b })


type Route
    = EventsRoute GithubEventSource
    | NotFoundRoute


type alias EventStream =
    { source : GithubEventSource
    , events : List GithubEvent
    , interval : Int
    , etag : String
    , error : Maybe Http.Error
    }


sourceLens : Lens Model GithubEventSource
sourceLens =
    eventStreamLens <|> Lens .source (\b a -> { a | source = b })


eventsLens : Lens Model (List GithubEvent)
eventsLens =
    eventStreamLens <|> Lens .events (\b a -> { a | events = b })


intervalLens : Lens Model Int
intervalLens =
    eventStreamLens <|> Lens .interval (\b a -> { a | interval = b })


etagLens : Lens Model String
etagLens =
    eventStreamLens <|> Lens .etag (\b a -> { a | etag = b })


errorLens : Lens Model (Maybe Http.Error)
errorLens =
    eventStreamLens <|> Lens .error (\b a -> { a | error = b })
