module Homepage.Update exposing (subscriptions, update)

import Homepage.Message exposing (Msg(..))
import Model exposing (Model)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SearchCommand input ->
            ( model, Cmd.none )
