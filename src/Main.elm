module Main exposing (main)

import Browser exposing (..)
import Browser.Navigation as Nav
import EventStream.Message
import EventStream.Update exposing (resetEventStreamIfSourceChanged)
import GitHub.APIv3 exposing (readCurrentUserInfo)
import GitHub.Message
import GitHub.Model
import GitHub.OAuthProxy exposing (requestAccessToken)
import Message exposing (Msg(..))
import Model exposing (..)
import Routing exposing (Route(..), modifyUrlGivenSource)
import Time
import Timeline.Message
import Timeline.Update
import Timeline.View
import Url exposing (Url)
import Util exposing (modifyModel, push, wrapCmd, wrapMsg)
import View


main : Program () Model Msg
main =
    Browser.application
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = OnUrlRequestMsg
        , onUrlChange = OnUrlChangeMsg
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.mode of
        Timeline ->
            if List.isEmpty model.eventStream.events then
                Sub.none

            else
                Time.every model.preferences.tickIntervalMilliseconds (\_ -> TickMsg)

        Homepage ->
            Sub.none


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        initialRoute =
            Routing.parseLocation url

        ( model, cmd ) =
            route initialRoute (initialModel key url)
    in
    ( model, Cmd.batch [ cmd ] )


route : Route -> Model -> ( Model, Cmd Msg )
route r model =
    case r of
        StartRoute ->
            ( { model | mode = Homepage }, Cmd.none )

        OAuthCode code ->
            ( model, requestAccessToken code |> Cmd.map LoginMsg )

        EventsRoute source ->
            ( model
                |> resetEventStreamIfSourceChanged source
                |> modeLens.set Timeline
            , push (EventStreamMsg EventStream.Message.ReadEvents)
            )

        RouteNotFound ->
            ( { model | mode = Homepage }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update m model =
    case m of
        OnUrlChangeMsg url ->
            route (Routing.parseLocation url) model
                |> modifyModel urlLens url

        OnUrlRequestMsg urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , pushUrl model url
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        LoginMsg (GitHub.OAuthProxy.OAuthToken token scope) ->
            ( { model | authorization = Token token scope }
            , readCurrentUserInfo (Token token scope) |> Cmd.map UserMsg
            )

        UserMsg (GitHub.Message.GitHubUserMsg (Ok response)) ->
            ( { model | user = Just response.content }
            , pushUrl model (modifyUrlGivenSource model.url (GitHub.Model.GitHubEventSourceUser response.content.login))
            )

        EventStreamMsg msg ->
            EventStream.Update.update msg model.authorization model
                |> wrapCmd EventStreamMsg

        TimelineMsg msg ->
            Timeline.Update.update msg model
                |> wrapCmd TimelineMsg

        TickMsg ->
            case model.mode of
                Homepage ->
                    ( model, Cmd.none )

                Timeline ->
                    Timeline.Update.update Timeline.Message.TickMsg model
                        |> wrapCmd TimelineMsg

        _ ->
            ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    case model.mode of
        Timeline ->
            { title = model.title
            , body =
                [ Timeline.View.view model
                    |> wrapMsg EventStreamMsg
                ]
            }

        Homepage ->
            { title = model.title
            , body = [ View.view model ]
            }


pushUrl : Model -> Url -> Cmd Msg
pushUrl model nextUrl =
    Nav.pushUrl model.key (Url.toString nextUrl)
