module EventStream.Message exposing (..)

import Github.Message


type Msg
    = NoOp
    | ReadEvents
    | ReadEventsNextPage String
    | GithubResponseEvents Github.Message.Msg
    | GithubResponseEventsNextPage Github.Message.Msg
