module Model exposing (Authorization(..), Mode(..), Model, eventStreamLens, eventStreamSourceLens, initialModel, modeLens, routeLens, urlLens)

import Browser.Navigation exposing (Key)
import EventStream.Model as EventStream exposing (Model, initialEventStream, sourceLens)
import GitHub.Model
import Monocle.Lens exposing (Lens, compose)
import Routing exposing (Route(..))
import Url exposing (Url)


type alias Model =
    { title : String
    , key : Key
    , mode : Mode
    , route : Route
    , eventStream : EventStream.Model
    , authorization : Authorization
    , user : Maybe GitHub.Model.GitHubUserInfo
    , url : Url
    }


title : String
title =
    "GitHub Activity Dashboard"


initialModel : Key -> Url -> Model
initialModel key url =
    { title = title
    , mode = Homepage
    , route = StartRoute
    , eventStream = initialEventStream
    , authorization = Unauthorized
    , user = Nothing
    , key = key
    , url = url
    }


type Mode
    = Homepage
    | Timeline


type Authorization
    = Unauthorized
    | Token String String


eventStreamLens : Lens Model EventStream.Model
eventStreamLens =
    Lens .eventStream (\b a -> { a | eventStream = b })


modeLens : Lens Model Mode
modeLens =
    Lens .mode (\b a -> { a | mode = b })


urlLens : Lens Model Url
urlLens =
    Lens .url (\b a -> { a | url = b })


routeLens : Lens Model Route
routeLens =
    Lens .route (\b a -> { a | route = b })


eventStreamSourceLens : Lens Model GitHub.Model.GitHubEventSource
eventStreamSourceLens =
    compose eventStreamLens sourceLens
