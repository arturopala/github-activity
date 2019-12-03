module Main exposing (main)

import Browser exposing (..)
import Browser.Navigation as Nav
import Cache
import EventStream.Message
import EventStream.Update exposing (resetEventStreamIfSourceChanged)
import GitHub.API3Request exposing (readCurrentUserInfo, readCurrentUserOrganisations)
import GitHub.API3Response
import GitHub.Authorization exposing (Authorization(..))
import GitHub.Endpoint
import GitHub.OAuth exposing (requestAccessToken)
import Homepage.Model exposing (sourceHistoryLens)
import Homepage.Update
import Homepage.View
import Json.Decode
import LocalStorage
import Message exposing (Msg(..))
import Mode exposing (Mode(..))
import Model exposing (..)
import Monocle.Lens as Lens
import Ports
import Routing exposing (Route(..), modifyUrlGivenSource)
import Task
import Time
import Timeline.Update
import Timeline.View
import Url exposing (Url)
import Util exposing (modifyModel, push)


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
    Sub.batch
        [ Homepage.Update.subscriptions model
        , Timeline.Update.subscriptions model
        , Ports.onFullScreenChange FullScreenSwitchEvent
        , Ports.listenToCache (Json.Decode.decodeValue Cache.cacheItemDecoder >> Result.withDefault NoOp)
        ]


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
                Token _ _ ->
                    case model.user of
                        Just _ ->
                            Cmd.none

                        Nothing ->
                            readCurrentUserInfo model.authorization |> Cmd.map Message.GitHubMsg

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
            ( model, push (ExchangeCodeForTokenCommand code) )

        EventsRoute source ->
            let
                model2 =
                    model
                        |> resetEventStreamIfSourceChanged source
                        |> modeLens.set Mode.Timeline
                        |> Util.appendIfDistinct source (Lens.compose homepageLens sourceHistoryLens)
            in
            ( model2
            , Cmd.batch
                [ push (EventStreamMsg EventStream.Message.ReadEvents)
                , LocalStorage.saveToLocalStorage model2
                ]
            )

        RouteNotFound ->
            ( model, push (NavigateCommand Nothing Nothing) )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AuthorizeUserCommand cmd ->
            ( { model | doAfterAuthorized = Just cmd }, Nav.load GitHub.OAuth.signInUrl )

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

        ExchangeCodeForTokenCommand code ->
            ( model
                |> authorizationCodeLens.set (Just code)
            , requestAccessToken code |> Cmd.map GotTokenEvent
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
                [ LocalStorage.saveToLocalStorage model2
                , push (NavigateCommand Nothing Nothing)
                ]
            )

        FullScreenSwitchEvent fullscreen ->
            ( { model | fullscreen = fullscreen }, Cmd.none )

        GotTimeZoneEvent zone ->
            ( { model | zone = zone }, Cmd.none )

        GotTokenEvent (GitHub.OAuth.OAuthToken token scope) ->
            let
                url =
                    model.url

                authorization =
                    Token token scope

                model2 =
                    model
                        |> authorizationLens.set authorization
                        |> authorizationCodeLens.set Nothing
            in
            ( model2
            , Cmd.batch
                [ LocalStorage.saveToLocalStorage model2
                , pushUrl model { url | query = Nothing }
                , readCurrentUserInfo authorization |> Cmd.map Message.GitHubMsg
                , model.doAfterAuthorized |> Maybe.withDefault Cmd.none
                ]
            )

        GotTokenEvent (GitHub.OAuth.OAuthError error) ->
            let
                cmd =
                    authorizationCodeLens.get model
                        |> Maybe.map (\c -> Util.delayMessage 5 (ExchangeCodeForTokenCommand c))
                        |> Maybe.withDefault Cmd.none
            in
            ( model, Cmd.batch [ cmd, Ports.logError error ] )

        GotUserEvent user ->
            ( { model | user = Just user }
            , readCurrentUserOrganisations model.authorization |> Cmd.map Message.GitHubMsg
            )

        GotUserOrganisationsEvent organisations ->
            ( { model | organisations = organisations }
            , Cmd.none
            )

        UrlChangedEvent url ->
            route (Routing.parseLocation url) model
                |> modifyModel urlLens url

        PutToCacheCommand endpoint body metadata ->
            ( model, Ports.putToCache (Cache.encodeCacheItem endpoint body metadata) )

        OrderFromCacheCommand endpoint ->
            ( model, Ports.orderFromCache (GitHub.Endpoint.toJson endpoint) )

        CacheResponseEvent endpoint body metadata ->
            GitHub.API3Response.onSuccess endpoint body metadata model

        GitHubMsg response ->
            case response of
                Ok ( endpoint, httpResponse ) ->
                    GitHub.API3Response.processResponse endpoint httpResponse model

                Err _ ->
                    ( model, Cmd.none )

        EventStreamMsg _ ->
            EventStream.Update.update msg model.authorization model

        TimelineMsg _ ->
            Timeline.Update.update msg model

        HomepageMsg _ ->
            Homepage.Update.update msg model

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
