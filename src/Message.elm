module Message exposing (..)

import Navigation exposing (Location)
import EventStream.Message exposing (Msg(..))

type Msg
    = NoOp
    | OnLocationChange Location
    | Timeline EventStream.Message.Msg