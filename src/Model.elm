module Model exposing (..)

import Http

type alias Model =
    { events: List GithubEvent
    , error: Maybe Http.Error
    }

type alias GithubEvent =
  { id : String
  , eventType : String
  , actor: GithubActor
  , repo: GithubRepo
  , payload: GithubPayload
  , created_at: String
  }

type alias GithubActor = 
    { display_login: String
    , avatar_url: String
    }

type alias GithubRepo = 
    { name: String
    , url: String
    }

type alias GithubPayload = 
    { size: Int
    }