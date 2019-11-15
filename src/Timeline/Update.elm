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
        pull source target =
            case source of
                head :: tail ->
                    if List.member head target then
                        pull tail target

                    else
                        ( tail
                        , (head :: target)
                            |> List.sortBy (.created_at >> posixToMillis >> negate)
                            |> List.take model.preferences.numberOfEventsOnDisplay
                        )

                [] ->
                    ( source, target )

        ( queue, display ) =
            pull model.eventStream.events model.timeline.events
    in
    model
        |> eventStreamEventsLens.set queue
        |> timelineEventsLens.set display
