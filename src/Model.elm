module Model exposing (Authorization(..), Mode(..), Model, eventStreamErrorLens, eventStreamEventsLens, eventStreamLens, eventStreamSourceLens, initialModel, limitsLens, modeLens, routeLens, timelineEventsLens, timelineLens, urlLens)

import Browser.Navigation exposing (Key)
import EventStream.Model as EventStream exposing (Model, sourceLens)
import GitHub.Model exposing (GitHubApiLimits, GitHubEvent)
import Http
import Monocle.Lens exposing (Lens, compose)
import Routing exposing (Route(..))
import Timeline.Model as Timeline
import Url exposing (Url)


type alias Model =
    { title : String
    , key : Key
    , mode : Mode
    , route : Route
    , eventStream : EventStream.Model
    , timeline : Timeline.Model
    , authorization : Authorization
    , user : Maybe GitHub.Model.GitHubUserInfo
    , preferences : Preferences
    , url : Url
    , limits : GitHubApiLimits
    }


title : String
title =
    "GitHub Activity Dashboard"


initialModel : Key -> Url -> Model
initialModel key url =
    { title = title
    , mode = Homepage
    , route = StartRoute
    , eventStream = EventStream.initialEventStream
    , timeline = Timeline.initialTimeline
    , authorization = Unauthorized
    , user = Nothing
    , preferences =
        { numberOfEventsOnDisplay = 100
        , maxNumberOfEventsInQueue = 1000
        , tickIntervalMilliseconds = 500
        }
    , key = key
    , url = url
    , limits = GitHubApiLimits 60 60 Nothing 120
    }


type Mode
    = Homepage
    | Timeline


type Authorization
    = Unauthorized
    | Token String String


type alias Preferences =
    { numberOfEventsOnDisplay : Int
    , maxNumberOfEventsInQueue : Int
    , tickIntervalMilliseconds : Float
    }


eventStreamLens : Lens Model EventStream.Model
eventStreamLens =
    Lens .eventStream (\b a -> { a | eventStream = b })


timelineLens : Lens Model Timeline.Model
timelineLens =
    Lens .timeline (\b a -> { a | timeline = b })


modeLens : Lens Model Mode
modeLens =
    Lens .mode (\b a -> { a | mode = b })


urlLens : Lens Model Url
urlLens =
    Lens .url (\b a -> { a | url = b })


routeLens : Lens Model Route
routeLens =
    Lens .route (\b a -> { a | route = b })


limitsLens : Lens Model GitHubApiLimits
limitsLens =
    Lens .limits (\b a -> { a | limits = b })


eventStreamSourceLens : Lens Model GitHub.Model.GitHubEventSource
eventStreamSourceLens =
    compose eventStreamLens sourceLens


eventStreamEventsLens : Lens Model (List GitHubEvent)
eventStreamEventsLens =
    compose eventStreamLens EventStream.eventsLens


eventStreamErrorLens : Lens Model (Maybe Http.Error)
eventStreamErrorLens =
    compose eventStreamLens EventStream.errorLens


timelineEventsLens : Lens Model (List GitHubEvent)
timelineEventsLens =
    compose timelineLens Timeline.eventsLens
