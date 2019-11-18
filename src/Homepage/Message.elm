module Homepage.Message exposing (Msg(..))

import GitHub.Model


type Msg
    = SearchCommand String
    | UserSearchResultEvent (List GitHub.Model.GitHubUserRef)
    | NoOp
