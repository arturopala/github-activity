module Util exposing (appendDistinctToList, appendIfDistinct, delayMessage, delayMessageUntil, modifyModel, push, removeFromList, wrapCmd, wrapModel, wrapMsg)

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


appendDistinctToList : a -> List a -> List a
appendDistinctToList a list =
    case list of
        [] ->
            a :: []

        x :: xs ->
            if a == x then
                list

            else
                x :: appendDistinctToList a xs


appendIfDistinct : a -> Lens b (List a) -> b -> b
appendIfDistinct a lens b =
    lens.get b |> appendDistinctToList a |> (\l -> lens.set l b)


removeFromList : a -> Lens b (List a) -> b -> b
removeFromList a lens b =
    lens.get b |> List.filter ((/=) a) |> (\l -> lens.set l b)
