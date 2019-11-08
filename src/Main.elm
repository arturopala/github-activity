module Main exposing (main)

import Browser exposing (..)
import Browser.Navigation as Nav
import EventStream.Message
import EventStream.Model exposing (initialEventStream)
import EventStream.Update
import GitHub.OAuthProxy exposing (requestAccessToken)
import Message exposing (Msg(..))
import Model exposing (..)
import Routing exposing (Route(..))
import Timeline.View
import Url exposing (Url)
import Util exposing (modifyModel, withCmd, wrapCmd, wrapModel, wrapMsg)
import View


main : Program () Model Msg
main =
    Browser.application
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = OnUrlRequest
        , onUrlChange = OnUrlChange
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


title : String
title =
    "GitHub Activity Dashboard"


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        initialRoute =
            Routing.parseLocation url

        initialModel =
            Model title key Welcome initialRoute initialEventStream Unauthorized

        ( model, cmd ) =
            route initialRoute initialModel
    in
    ( model, cmd )


route : Route -> Model -> ( Model, Cmd Msg )
route r model =
    case r of
        StartRoute ->
            let
                mode =
                    case model.authorization of
                        Token _ ->
                            Timeline

                        _ ->
                            Welcome
            in
            ( { model | mode = mode }, Cmd.none )

        OAuthCode code ->
            ( model, requestAccessToken code |> Cmd.map Authorized )

        EventsRoute source ->
            ( eventStreamSourceLens.set source model, withCmd (ShowTimeline EventStream.Message.ReadEvents) )

        RouteNotFound ->
            ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update m model =
    case m of
        OnUrlChange location ->
            route (Routing.parseLocation location) model

        OnUrlRequest urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        Authorized event ->
            case event of
                GitHub.OAuthProxy.OAuthToken token scope ->
                    let
                        mode =
                            if model.mode == Welcome then
                                Timeline

                            else
                                model.mode
                    in
                    ( { model | authorization = Token token, title = title ++ " - " ++ token, mode = mode }
                    , Nav.pushUrl model.key "/#events/users/arturopala"
                    )

                GitHub.OAuthProxy.OAuthError error ->
                    ( { model | authorization = Unauthorized, mode = Welcome }, Cmd.none )

        ShowTimeline msg ->
            case model.authorization of
                Token token ->
                    EventStream.Update.update msg (Just token) model.eventStream
                        |> wrapModel eventStreamLens model
                        |> modifyModel modeLens Timeline
                        |> wrapCmd ShowTimeline

                _ ->
                    EventStream.Update.update msg Nothing model.eventStream
                        |> wrapModel eventStreamLens model
                        |> modifyModel modeLens Timeline
                        |> wrapCmd ShowTimeline

        _ ->
            ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    case model.mode of
        Timeline ->
            { title = model.title
            , body =
                [ Timeline.View.view model.eventStream
                    |> wrapMsg ShowTimeline
                ]
            }

        _ ->
            { title = model.title
            , body = [ View.view model ]
            }
