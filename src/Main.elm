module Main exposing (main)

import Navigation exposing (Location, modifyUrl)
import Routing exposing (Route(..))
import Util exposing (wrapCmdIn, wrapModelIn, wrapMsgIn)
import Html exposing (Html)
import Model exposing (..)
import EventStream.Message
import EventStream.Model as EventStream exposing (defaultEventSource)
import EventStream.Update
import Timeline.View
import Monocle.Lens exposing (Lens, tuple3)


type Msg
    = NoOp
    | OnLocationChange Location
    | Timeline EventStream.Message.Msg


main : Program Never Model Msg
main =
    Navigation.program OnLocationChange
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


init : Location -> ( Model, Cmd Msg )
init location =
    let
        route =
            Routing.parseLocation location

        (eventStream,cmd) =
            EventStream.Update.init route
            |> wrapCmdIn Timeline

    in
       Model route eventStream ! [cmd]


route : Route -> Model -> ( Model, Cmd Msg )
route route model =
    case route of
        EventsRoute _ ->
            EventStream.Update.route route model.eventStream
                |> wrapModelIn eventStreamLens model
                |> wrapCmdIn Timeline

        NotFoundRoute ->
            model ! [ modifyUrl (Routing.eventsSourceUrl defaultEventSource) ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnLocationChange location ->
            route (Routing.parseLocation location) model

        Timeline msg ->
            EventStream.Update.update msg model.eventStream
                |> wrapModelIn eventStreamLens model
                |> wrapCmdIn Timeline

        _ ->
            ( model, Cmd.none )



view : Model -> Html Msg
view model =
    Timeline.View.view model
        |> wrapMsgIn Timeline

