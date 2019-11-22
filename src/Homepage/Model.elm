module Homepage.Model exposing (Model, initialHomepage, searchLens, sourceHistoryLens)

import Components.UserSearch
import GitHub.Model
import Monocle.Lens exposing (Lens)


type alias Model =
    { search : Components.UserSearch.Model
    , sourceHistory : List GitHub.Model.GitHubEventSource
    }


initialHomepage : Model
initialHomepage =
    { search = Components.UserSearch.init
    , sourceHistory = []
    }


searchLens : Lens Model Components.UserSearch.Model
searchLens =
    Lens .search (\b a -> { a | search = b })


sourceHistoryLens : Lens Model (List GitHub.Model.GitHubEventSource)
sourceHistoryLens =
    Lens .sourceHistory (\b a -> { a | sourceHistory = b })
