module Homepage.Update exposing (subscriptions, update)

import GitHub.APIv3
import GitHub.Message
import GitHub.Model
import Homepage.Message exposing (Msg(..))
import Homepage.Model exposing (usersFoundLens)
import Model exposing (Model)
import Monocle.Lens as Lens exposing (Lens)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SearchCommand input ->
            if String.length input > 3 then
                ( model
                , GitHub.APIv3.searchUsersByLogin input model.authorization
                    |> Cmd.map gitHubApiResponseAsMsg
                )

            else
                ( model |> homepageUsersFoundLens.set [], Cmd.none )

        UserSearchResultEvent users ->
            ( model |> homepageUsersFoundLens.set users, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


gitHubApiResponseAsMsg : GitHub.Message.Msg -> Msg
gitHubApiResponseAsMsg msg =
    case msg of
        GitHub.Message.GitHubUserSearchMsg (Ok response) ->
            UserSearchResultEvent response.content.items

        _ ->
            NoOp


homepageUsersFoundLens : Lens Model (List GitHub.Model.GitHubUserRef)
homepageUsersFoundLens =
    Lens.compose Model.homepageLens usersFoundLens
