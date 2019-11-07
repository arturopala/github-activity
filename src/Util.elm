module Util exposing (delaySeconds, modifyModel, withCmd, wrapCmd, wrapModel, wrapMsg)

import Html exposing (Html)
import Monocle.Lens exposing (Lens)
import Process
import Task


delaySeconds : Int -> m -> Cmd m
delaySeconds interval msg =
    Process.sleep (toFloat interval * 1000)
        |> Task.perform (\_ -> msg)


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


withCmd : a -> Cmd a
withCmd msg =
    Task.perform identity (Task.succeed msg)
