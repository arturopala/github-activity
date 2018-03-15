module Main exposing (main)

import Navigation exposing (Location, modifyUrl)
import Routing
import Time
import Task
import Process
import Main.Message exposing (..)
import Main.Model exposing (..)
import Main.View
import Main.Update
import Github.Model exposing (GithubEventSource(..))


main : Program Never Model Msg
main =
    Navigation.program OnLocationChange
        { view = Main.View.view
        , init = init
        , update = Main.Update.update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


init : Location -> ( Model, Cmd Msg )
init location =
    let
        route =
            Routing.parseLocation location

        source =
            case route of
                EventsRoute source ->
                    source

                _ ->
                    GithubUser defaultUser
    in
        { route = route
        , eventStream =
            { source = source
            , events = []
            , interval = 60
            , etag = ""
            , error = Nothing
            }
        }
            ! [ modifyUrl (Routing.eventsSourceUrl source) ]
