module Timeline.Update exposing (subscriptions, update)

import EventStream.Model
import List exposing ((::))
import Mode
import Model exposing (Model, eventStreamEventsLens, timelineActiveLens, timelineEventsLens)
import Time exposing (posixToMillis)
import Timeline.Message exposing (Msg(..))
import Timeline.Model


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.mode of
        Mode.Timeline ->
            if List.isEmpty model.eventStream.events || not model.timeline.active then
                Sub.none

            else
                Time.every model.preferences.tickIntervalMilliseconds (\_ -> TickEvent)

        _ ->
            Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TickEvent ->
            ( updateEventsOnDisplay model
            , Cmd.none
            )

        PlayCommand ->
            ( model |> timelineActiveLens.set True
            , Cmd.none
            )

        PauseCommand ->
            ( model |> timelineActiveLens.set False
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
