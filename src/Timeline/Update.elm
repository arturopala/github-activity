module Timeline.Update exposing (subscriptions, update)

import EventStream.Model
import GitHub.Model
import List exposing ((::))
import Message exposing (Msg(..))
import Mode
import Model exposing (Model, eventStreamEventsLens, timelineActiveLens, timelineEventsLens)
import Time exposing (posixToMillis)
import Timeline.Message
import Timeline.Model


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.mode of
        Mode.Timeline ->
            if List.isEmpty model.eventStream.events || not model.timeline.active then
                Sub.none

            else
                Time.every model.preferences.tickIntervalMilliseconds (\_ -> TimelineMsg <| Timeline.Message.TickEvent)

        _ ->
            Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TimelineMsg msg2 ->
            case msg2 of
                Timeline.Message.TickEvent ->
                    ( updateEventsOnDisplay model
                    , Cmd.none
                    )

                Timeline.Message.PlayCommand ->
                    ( model |> timelineActiveLens.set True
                    , Cmd.none
                    )

                Timeline.Message.PauseCommand ->
                    ( model |> timelineActiveLens.set False
                    , Cmd.none
                    )

        _ ->
            ( model, Cmd.none )


numberOfEventsToStreamWhenStarted : Int
numberOfEventsToStreamWhenStarted =
    20


updateEventsOnDisplay : Model -> Model
updateEventsOnDisplay model =
    if List.isEmpty model.timeline.events then
        let
            reduced =
                model.eventStream.events
                    |> List.drop (List.length model.eventStream.events - model.preferences.numberOfEventsOnDisplay - numberOfEventsToStreamWhenStarted)

            reducedLength =
                List.length reduced

            ( queue, display ) =
                pullNEvents (reducedLength - numberOfEventsToStreamWhenStarted) reduced model.timeline.events model.preferences.numberOfEventsOnDisplay
        in
        model
            |> eventStreamEventsLens.set queue
            |> timelineEventsLens.set display

    else
        let
            ( queue, display ) =
                pullEvent model.eventStream.events model.timeline.events model.preferences.numberOfEventsOnDisplay
        in
        model
            |> eventStreamEventsLens.set queue
            |> timelineEventsLens.set display


pullNEvents : Int -> List GitHub.Model.GitHubEvent -> List GitHub.Model.GitHubEvent -> Int -> ( List GitHub.Model.GitHubEvent, List GitHub.Model.GitHubEvent )
pullNEvents count source target maxTargetSize =
    if count == 0 || List.isEmpty source then
        ( source, target )

    else
        let
            ( source2, target2 ) =
                pullEvent source target maxTargetSize
        in
        pullNEvents (count - 1) source2 target2 maxTargetSize


pullEvent : List GitHub.Model.GitHubEvent -> List GitHub.Model.GitHubEvent -> Int -> ( List GitHub.Model.GitHubEvent, List GitHub.Model.GitHubEvent )
pullEvent source target maxTargetSize =
    case source of
        head :: tail ->
            if List.member head target then
                pullEvent tail target maxTargetSize

            else
                ( tail
                , (head :: target)
                    |> List.sortBy (.created_at >> posixToMillis >> negate)
                    |> List.take maxTargetSize
                )

        [] ->
            ( source, target )
