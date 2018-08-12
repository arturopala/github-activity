module Main exposing (main)

import Navigation exposing (Location, modifyUrl)
import Routing exposing (Route(..))
import Util exposing (wrapCmdIn, wrapModelIn, wrapMsgIn)
import Html exposing (Html)
import Model exposing (..)
import EventStream.Model as EventStream exposing (defaultEventSource, initialEventStream)
import EventStream.Update
import Timeline.View
import View
import Message exposing (Msg(..))
import Debug exposing(log)


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
        initialRoute =
            Routing.parseLocation location

        initialModel = Model initialRoute initialEventStream Unauthenticated

        (model, cmd) = route initialRoute initialModel
    in
        model ! [ cmd ]


route : Route -> Model -> ( Model, Cmd Msg )
route route model =
    case route of
        StartRoute maybeCode ->
            case maybeCode of
                Nothing ->
                    model ! [ Cmd.none ]
                Just code ->
                    model ! [ modifyUrl Routing.rootUrl ]

        EventsRoute source ->
            EventStream.Update.readFrom source model.eventStream
                |> wrapModelIn eventStreamLens model
                |> wrapCmdIn Timeline

        NotFoundRoute ->
            model ! [ modifyUrl Routing.rootUrl ]


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
    case model.authentication of
        Unauthenticated ->
            View.view model
        Token token ->
            Timeline.View.view model.eventStream
            |> wrapMsgIn Timeline
