module Main.View exposing (view)

import Html exposing (Html)
import Main.Model exposing (Model)
import Main.Message exposing (Msg)
import Timeline.View


view : Model -> Html Msg
view model =
    Timeline.View.view model.eventStream
