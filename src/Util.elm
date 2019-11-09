module Util exposing (delayMessage, delayMessageUntil, modifyModel, push, wrapCmd, wrapModel, wrapMsg)

import Html exposing (Html)
import Monocle.Lens exposing (Lens)
import Process
import Task
import Time exposing (Posix)


wrapCmd : (a -> b) -> ( m, Cmd a ) -> ( m, Cmd b )
wrapCmd f ( m, cmd ) =
    ( m, cmd |> Cmd.map f )


wrapModel : Lens a b -> a -> ( b, c ) -> ( a, c )
wrapModel lens a ( b, c ) =
    ( lens.set b a, c )


modifyModel : Lens a b -> b -> ( a, c ) -> ( a, c )
modifyModel lens a ( b, c ) =
    ( lens.set a b, c )


wrapMsg : (a -> b) -> Html a -> Html b
wrapMsg f html =
    html |> Html.map f


push : a -> Cmd a
push msg =
    Task.perform identity (Task.succeed msg)


delayMessage : Int -> m -> Cmd m
delayMessage interval msg =
    Process.sleep (toFloat (interval * 1000))
        |> Task.perform (\_ -> msg)


delayMessageUntil : Posix -> m -> Cmd m
delayMessageUntil timestamp msg =
    Time.now
        |> Task.map Time.posixToMillis
        |> Task.map
            (\t -> Time.posixToMillis timestamp - t)
        |> Task.map
            (\i ->
                if i < 0 then
                    0

                else
                    i
            )
        |> Task.map toFloat
        |> Task.andThen Process.sleep
        |> Task.perform (\_ -> msg)
