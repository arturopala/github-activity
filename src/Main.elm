module Main exposing (main)

import Browser exposing (..)
import Browser.Navigation as Nav
import EventStream.Message
import EventStream.Update exposing (resetEventStreamIfSourceChanged)
import GitHub.APIv3 exposing (readCurrentUserInfo, readCurrentUserOrganisations)
import GitHub.Message
import GitHub.Model
import GitHub.OAuthProxy exposing (requestAccessToken)
import Homepage.View
import Message exposing (Msg(..))
import Mode exposing (Mode(..))
import Model exposing (..)
import Ports
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
            route initialRoute (initialModel key url flags)

        readUserCmd =
            case model.authorization of
                Token token scope ->
                    case model.user of
                        Just user ->
                            Cmd.none

                        Nothing ->
                            readCurrentUserInfo (Token token scope) |> Cmd.map GotGitHubApiResponseEvent

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
            ( model
                |> resetEventStreamIfSourceChanged source
                |> modeLens.set Mode.Timeline
            , push (EventStreamMsg EventStream.Message.ReadEvents)
            )

        RouteNotFound ->
            ( model, push (NavigateCommand Nothing Nothing) )


update : Msg -> Model -> ( Model, Cmd Msg )
update m model =
    case m of
        UrlChangedEvent url ->
            route (Routing.parseLocation url) model
                |> modifyModel urlLens url

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

        AuthorizeUserCommand cmd ->
            ( { model | doAfterAuthorized = Just cmd }, Nav.load Routing.signInUrl )

        SignOutCommand ->
            ( { model
                | authorization = Unauthorized
                , user = Nothing
                , organisations = []
              }
            , Cmd.batch
                [ Ports.storeToken ""
                , push (NavigateCommand Nothing Nothing)
                ]
            )

        GotTokenEvent (GitHub.OAuthProxy.OAuthToken token scope) ->
            let
                url =
                    model.url
            in
            ( { model | authorization = Token token scope }
            , Cmd.batch
                [ saveToken (token ++ "," ++ scope)
                , pushUrl model { url | query = Nothing }
                , readCurrentUserInfo (Token token scope) |> Cmd.map GotGitHubApiResponseEvent
                , model.doAfterAuthorized |> Maybe.withDefault Cmd.none
                ]
            )

        GotGitHubApiResponseEvent (GitHub.Message.GitHubUserMsg (Ok response)) ->
            ( { model | user = Just response.content }
            , readCurrentUserOrganisations model.authorization |> Cmd.map GotGitHubApiResponseEvent
            )

        GotGitHubApiResponseEvent (GitHub.Message.GitHubUserOrganisationsMsg (Ok response)) ->
            ( { model | organisations = response.content }
            , Cmd.none
            )

        EventStreamMsg msg ->
            EventStream.Update.update msg model.authorization model
                |> wrapCmd EventStreamMsg

        TimelineMsg msg ->
            Timeline.Update.update msg model
                |> wrapCmd TimelineMsg

        GotTimeZoneEvent zone ->
            ( { model | zone = zone }, Cmd.none )

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

        _ ->
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


saveToken : String -> Cmd msg
saveToken token =
    Ports.storeToken token
