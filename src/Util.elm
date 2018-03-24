module Util exposing (..)

import Time
import Task
import Process
import Html exposing (Html)
import Monocle.Lens exposing (Lens)


delaySeconds : Int -> m -> Cmd m
delaySeconds interval msg =
    Process.sleep ((toFloat interval) * Time.second)
        |> Task.perform (\_ -> msg)


wrapCmdIn : (a -> b) -> ( m, Cmd a ) -> ( m, Cmd b )
wrapCmdIn f ( m, cmd ) =
    ( m, cmd |> Cmd.map f )


wrapModelIn : Lens a b -> a -> ( b, c ) -> ( a, c )
wrapModelIn lens a (b, c ) =
    ( lens.set b a, c)


wrapMsgIn : (a -> b) -> Html a -> Html b
wrapMsgIn f html =
    html |> Html.map f
