module Timeline.Update exposing (update)

import EventStream.Model
import List exposing ((::))
import Model exposing (Model, eventStreamEventsLens, timelineEventsLens)
import Time exposing (posixToMillis)
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
            case model.eventStream.events of
                head :: _ ->
                    (head :: model.timeline.events)
                        |> List.sortBy (.created_at >> posixToMillis >> negate)
                        |> List.take model.preferences.numberOfEventsOnDisplay

                [] ->
                    model.timeline.events

        queue =
            model.eventStream.events
                |> List.drop 1
    in
    model
        |> eventStreamEventsLens.set queue
        |> timelineEventsLens.set display
