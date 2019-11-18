module Homepage.Model exposing (Model, initialHomepage, usersFoundLens)

import GitHub.Model
import Monocle.Lens exposing (Lens)


type alias Model =
    { usersFound : List GitHub.Model.GitHubUserRef
    }


initialHomepage : Model
initialHomepage =
    Model []


usersFoundLens : Lens Model (List GitHub.Model.GitHubUserRef)
usersFoundLens =
    Lens .usersFound (\b a -> { a | usersFound = b })
