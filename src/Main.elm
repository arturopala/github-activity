module Main exposing (main)

import Browser exposing (..)
import Browser.Navigation as Nav
import EventStream.Message
import EventStream.Update exposing (resetEventStreamIfSourceChanged)
import GitHub.APIv3 exposing (readCurrentUserInfo, readCurrentUserOrganisations)
import GitHub.Message
import GitHub.Model
import GitHub.OAuthProxy exposing (requestAccessToken)
import Homepage.Update
import Homepage.View
import LocalStorage
import Message exposing (Msg(..))
import Mode exposing (Mode(..))
import Model exposing (..)
import Routing exposing (Route(..), modifyUrlGivenSource)
import Task
import Time
import Timeline.Update
import Timeline.View
import Url exposing (Url)
import Util exposing (modifyModel, push, wrapCmd)


main : Program (Maybe String) Model Msg
main =
    Browser.application
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = ChangeUrlCommand
        , onUrlChange = UrlChangedEvent
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Timeline.Update.subscriptions model
        |> Sub.map TimelineMsg


init : Maybe String -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        initialRoute =
            Routing.parseLocation url

        ( model, cmd ) =
            let
                model2 =
                    initialModel key url
            in
            route initialRoute
                (model2
                    |> LocalStorage.decodeAndOverlayState flags
                    |> Maybe.withDefault model2
                )

        readUserCmd =
            case model.authorization of
                Token token scope ->
                    case model.user of
                        Just user ->
                            Cmd.none

                        Nothing ->
                            readCurrentUserInfo (Token token scope) |> Cmd.map gitHubApiResponseAsMsg

                Unauthorized ->
                    Cmd.none
    in
    ( model, Cmd.batch [ Task.perform GotTimeZoneEvent Time.here, readUserCmd, cmd ] )


route : Route -> Model -> ( Model, Cmd Msg )
route r model =
    case r of
        StartRoute ->
            ( { model | mode = Mode.Homepage }, Cmd.none )

        OAuthCode code ->
            ( model, requestAccessToken code |> Cmd.map GotTokenEvent )

        EventsRoute source ->
            let
                model2 =
                    model
                        |> resetEventStreamIfSourceChanged source
                        |> modeLens.set Mode.Timeline
            in
            ( model2
            , Cmd.batch
                [ LocalStorage.extractAndSaveState model2
                , push (EventStreamMsg EventStream.Message.ReadEvents)
                ]
            )

        RouteNotFound ->
            ( model, push (NavigateCommand Nothing Nothing) )


update : Msg -> Model -> ( Model, Cmd Msg )
update m model =
    case m of
        AuthorizeUserCommand cmd ->
            ( { model | doAfterAuthorized = Just cmd }, Nav.load Routing.signInUrl )

        ChangeEventSourceCommand source ->
            let
                cmd =
                    case model.authorization of
                        Unauthorized ->
                            push (AuthorizeUserCommand (push (ChangeEventSourceCommand source)))

                        Token _ _ ->
                            pushUrl model (modifyUrlGivenSource model.url source)
            in
            ( model, cmd )

        ChangeUrlCommand urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , pushUrl model url
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        NavigateCommand maybeFragment maybeQuery ->
            let
                url =
                    model.url
            in
            ( model, pushUrl model { url | fragment = maybeFragment, query = maybeQuery } )

        SignOutCommand ->
            let
                model2 =
                    { model
                        | authorization = Unauthorized
                        , user = Nothing
                        , organisations = []
                    }
            in
            ( model2
            , Cmd.batch
                [ LocalStorage.extractAndSaveState model2
                , push (NavigateCommand Nothing Nothing)
                ]
            )

        GotTimeZoneEvent zone ->
            ( { model | zone = zone }, Cmd.none )

        GotTokenEvent (GitHub.OAuthProxy.OAuthToken token scope) ->
            let
                url =
                    model.url

                model2 =
                    { model | authorization = Token token scope }
            in
            ( model2
            , Cmd.batch
                [ LocalStorage.extractAndSaveState model2
                , pushUrl model { url | query = Nothing }
                , readCurrentUserInfo (Token token scope) |> Cmd.map gitHubApiResponseAsMsg
                , model.doAfterAuthorized |> Maybe.withDefault Cmd.none
                ]
            )

        GotTokenEvent (GitHub.OAuthProxy.OAuthError error) ->
            ( model, Cmd.none )

        ReadUserEvent user ->
            ( { model | user = Just user }
            , readCurrentUserOrganisations model.authorization |> Cmd.map gitHubApiResponseAsMsg
            )

        ReadUserOrganisationsEvent organisations ->
            ( { model | organisations = organisations }
            , Cmd.none
            )

        UrlChangedEvent url ->
            route (Routing.parseLocation url) model
                |> modifyModel urlLens url

        EventStreamMsg msg ->
            EventStream.Update.update msg model.authorization model
                |> wrapCmd EventStreamMsg

        TimelineMsg msg ->
            Timeline.Update.update msg model
                |> wrapCmd TimelineMsg

        HomepageMsg msg ->
            Homepage.Update.update msg model
                |> wrapCmd HomepageMsg

        NoOp ->
            ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    case model.mode of
        Mode.Homepage ->
            { title = model.title
            , body = [ Homepage.View.view model ]
            }

        Mode.Timeline ->
            { title = model.title
            , body =
                [ Timeline.View.view model
                ]
            }


pushUrl : Model -> Url -> Cmd Msg
pushUrl model nextUrl =
    Nav.pushUrl model.key (Url.toString nextUrl)


gitHubApiResponseAsMsg : GitHub.Message.Msg -> Msg
gitHubApiResponseAsMsg msg =
    case msg of
        GitHub.Message.GitHubUserMsg (Ok response) ->
            ReadUserEvent response.content

        GitHub.Message.GitHubUserOrganisationsMsg (Ok response) ->
            ReadUserOrganisationsEvent response.content

        _ ->
            NoOp
