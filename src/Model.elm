module Model exposing (..)

import Http
import Time.DateTime as DateTime


type alias Model =
    { events : List GithubEvent
    , error : Maybe Http.Error
    }


type alias GithubEvent =
    { id : String
    , eventType : String
    , actor : GithubActor
    , repo : GithubRepo
    , payload : GithubPayload
    , created_at : DateTime.DateTime
    }


type alias GithubActor =
    { display_login : String
    , avatar_url : String
    }


type alias GithubRepo =
    { name : String
    , url : String
    }


type alias GithubPayload =
    { size : Int
    }
