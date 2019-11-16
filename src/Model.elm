module Model exposing (Authorization(..), Model, authorizationLens, downloadingLens, eventStreamChunksLens, eventStreamErrorLens, eventStreamEtagLens, eventStreamEventsLens, eventStreamLens, eventStreamSourceLens, initialModel, limitsLens, modeLens, routeLens, timelineActiveLens, timelineEventsLens, timelineLens, urlLens)

import Browser.Navigation exposing (Key)
import EventStream.Model as EventStream exposing (Model, etagLens, sourceLens)
import GitHub.Model exposing (GitHubApiLimits, GitHubEvent)
import Http
import Message exposing (Msg)
import Mode exposing (Mode)
import Monocle.Lens exposing (Lens, compose)
import Routing exposing (Route(..))
import Time exposing (Zone)
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
    , user : Maybe GitHub.Model.GitHubUser
    , organisations : List GitHub.Model.GitHubOrganisation
    , preferences : Preferences
    , url : Url
    , limits : GitHubApiLimits
    , zone : Zone
    , doAfterAuthorized : Maybe (Cmd Msg)
    , downloading : Bool
    }


title : String
title =
    "GitHub Activity"


initialModel : Key -> Url -> Model
initialModel key url =
    { title = title
    , mode = Mode.Homepage
    , route = StartRoute
    , eventStream = EventStream.initialEventStream
    , timeline = Timeline.initialTimeline
    , authorization = Unauthorized
    , user = Nothing
    , organisations = []
    , preferences =
        { numberOfEventsOnDisplay = 200
        , maxNumberOfEventsInQueue = 1000
        , tickIntervalMilliseconds = 500
        }
    , key = key
    , url = url
    , limits = GitHubApiLimits 60 60 Nothing 120
    , zone = Time.utc
    , doAfterAuthorized = Nothing
    , downloading = False
    }


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


downloadingLens : Lens Model Bool
downloadingLens =
    Lens .downloading (\b a -> { a | downloading = b })


authorizationLens : Lens Model Authorization
authorizationLens =
    Lens .authorization (\b a -> { a | authorization = b })


eventStreamSourceLens : Lens Model GitHub.Model.GitHubEventSource
eventStreamSourceLens =
    compose eventStreamLens sourceLens


eventStreamEtagLens : Lens Model String
eventStreamEtagLens =
    compose eventStreamLens etagLens


eventStreamEventsLens : Lens Model (List GitHubEvent)
eventStreamEventsLens =
    compose eventStreamLens EventStream.eventsLens


eventStreamChunksLens : Lens Model (List GitHubEvent)
eventStreamChunksLens =
    compose eventStreamLens EventStream.chunksLens


eventStreamErrorLens : Lens Model (Maybe Http.Error)
eventStreamErrorLens =
    compose eventStreamLens EventStream.errorLens


timelineEventsLens : Lens Model (List GitHubEvent)
timelineEventsLens =
    compose timelineLens Timeline.eventsLens


timelineActiveLens : Lens Model Bool
timelineActiveLens =
    compose timelineLens Timeline.activeLens