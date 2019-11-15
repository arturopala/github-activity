module Model exposing (Authorization(..), Model, eventStreamErrorLens, eventStreamEtagLens, eventStreamEventsLens, eventStreamLens, eventStreamSourceLens, initialModel, limitsLens, modeLens, routeLens, timelineActiveLens, timelineEventsLens, timelineLens, urlLens)

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
    }


title : String
title =
    "GitHub Activity Dashboard"


initialModel : Key -> Url -> Maybe String -> Model
initialModel key url flags =
    { title = title
    , mode = Mode.Homepage
    , route = StartRoute
    , eventStream = EventStream.initialEventStream
    , timeline = Timeline.initialTimeline
    , authorization = parseToken flags
    , user = Nothing
    , organisations = []
    , preferences =
        { numberOfEventsOnDisplay = 200
        , maxNumberOfEventsInQueue = 1000
        , tickIntervalMilliseconds = 250
        }
    , key = key
    , url = url
    , limits = GitHubApiLimits 60 60 Nothing 120
    , zone = Time.utc
    , doAfterAuthorized = Nothing
    }


type Authorization
    = Unauthorized
    | Token String String


type alias Preferences =
    { numberOfEventsOnDisplay : Int
    , maxNumberOfEventsInQueue : Int
    , tickIntervalMilliseconds : Float
    }


parseToken : Maybe String -> Authorization
parseToken s =
    let
        parts =
            s |> Maybe.map (String.split ",")

        token =
            parts |> Maybe.andThen List.head

        scope =
            parts |> Maybe.map (List.drop 1) |> Maybe.andThen List.head |> Maybe.withDefault ""
    in
    case token of
        Just value ->
            Token value scope

        Nothing ->
            Unauthorized


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


eventStreamEtagLens : Lens Model String
eventStreamEtagLens =
    compose eventStreamLens etagLens


eventStreamEventsLens : Lens Model (List GitHubEvent)
eventStreamEventsLens =
    compose eventStreamLens EventStream.eventsLens


eventStreamErrorLens : Lens Model (Maybe Http.Error)
eventStreamErrorLens =
    compose eventStreamLens EventStream.errorLens


timelineEventsLens : Lens Model (List GitHubEvent)
timelineEventsLens =
    compose timelineLens Timeline.eventsLens


timelineActiveLens : Lens Model Bool
timelineActiveLens =
    compose timelineLens Timeline.activeLens
