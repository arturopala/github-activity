module Timeline.Update exposing (update)

import EventStream.Model
import List exposing ((::))
import Model exposing (Model, eventStreamEventsLens, timelineEventsLens)
import Timeline.Message exposing (Msg(..))
import Timeline.Model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TickMsg ->
            ( updateEventsOnDisplay model
            , Cmd.none
            )


updateEventsOnDisplay : Model -> Model
updateEventsOnDisplay model =
    let
        display =
            model.eventStream.events
                |> List.head
                |> Maybe.map (\v -> v :: model.timeline.events)
                |> Maybe.map (List.take model.preferences.numberOfEventsOnDisplay)
                |> Maybe.withDefault model.timeline.events

        queue =
            model.eventStream.events
                |> List.drop 1
    in
    model
        |> eventStreamEventsLens.set queue
        |> timelineEventsLens.set display
