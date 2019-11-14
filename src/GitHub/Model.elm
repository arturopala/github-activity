module GitHub.Model exposing (GitHubApiLimits, GitHubError, GitHubEvent, GitHubEventActor, GitHubEventPayload(..), GitHubEventSource(..), GitHubEventsChunk, GitHubOrganisation, GitHubPullRequest, GitHubPullRequestEventPayload, GitHubReference, GitHubReleaseEventPayload, GitHubReleaseRef, GitHubRepoRef, GitHubRepository, GitHubResponse, GitHubUser, GitHubUserRef)

import Dict exposing (Dict)
import Time exposing (Posix)
import Url exposing (Url)


type alias GitHubResponse a =
    { content : a
    , etag : String
    , links : Dict String String
    , limits : GitHubApiLimits
    }


type alias GitHubApiLimits =
    { xRateLimit : Int
    , xRateRemaining : Int
    , xRateReset : Maybe Posix
    , xPollInterval : Int
    }


type alias GitHubError =
    { status : Int
    }


type alias GitHubEventsChunk =
    GitHubResponse (List GitHubEvent)


type GitHubEventSource
    = GitHubEventSourceDefault
    | GitHubEventSourceUser String
    | GitHubEventSourceOrganisation String
    | GitHubEventSourceRepository String String


type alias GitHubEvent =
    { id : String
    , eventType : String
    , actor : GitHubEventActor
    , repo : GitHubRepoRef
    , payload : GitHubEventPayload
    , created_at : Posix
    }


type alias GitHubEventActor =
    { display_login : String
    , avatar_url : String
    }


type alias GitHubRepoRef =
    { id : Int
    , name : String
    , url : Url
    }


type alias GitHubRepository =
    { id : Int
    , name : String
    , full_name : String
    , url : Url
    , html_url : Url
    , events_url : Url
    , owner : GitHubUser
    , private : Bool
    , fork : Bool
    , forks_count : Int
    , watchers_count : Int
    , subscribers_count : Int
    , network_count : Int
    , size : Int
    , open_issues_count : Int
    , default_branch : String
    , topics : List String
    , created_at : Posix
    , updated_at : Posix
    , pushed_at : Posix
    }


type alias GitHubReference =
    { label : String
    , ref : String
    , sha : String
    , user : GitHubUserRef
    , repo : GitHubRepoRef
    }


type GitHubEventPayload
    = GitHubPullRequestEvent GitHubPullRequestEventPayload
    | GitHubReleaseEvent GitHubReleaseEventPayload
    | GitHubOtherEventPayload


type alias GitHubPullRequestEventPayload =
    { action : String
    , number : Int
    , pull_request : GitHubPullRequest
    }


type alias GitHubPullRequest =
    { id : Int
    , url : Url
    , html_url : Url
    , diff_url : Url
    , commits_url : Url
    , comments_url : Url
    , state : String
    , title : String
    , body : String
    , created_at : Posix
    , merged_at : Maybe Posix
    , merged_commit_sha : Maybe String
    , user : GitHubUserRef
    , assignee : Maybe GitHubUserRef
    , assignees : List GitHubUserRef
    , requested_reviewers : List GitHubUserRef
    , merged : Bool
    , mergeable : Maybe Bool
    , rebaseable : Maybe Bool
    , mergeable_state : String
    , merged_by : Maybe GitHubUserRef
    , comments : Int
    , review_comments : Int
    , commits : Int
    , additions : Int
    , deletions : Int
    , changed_files : Int
    , head : GitHubReference
    , base : GitHubReference
    }


type alias GitHubReleaseEventPayload =
    { action : String
    , release : GitHubReleaseRef
    }


type alias GitHubReleaseRef =
    { id : Int
    , url : Url
    , html_url : Url
    , tag_name : String
    , body : Maybe String
    , draft : Bool
    , prerelease : Bool
    }


type alias GitHubUser =
    { id : Int
    , login : String
    , avatar_url : Url
    , url : Url
    , html_url : Url
    , organizations_url : Url
    , repos_url : Url
    , events_url : Url
    , received_events_url : Url
    , type_ : String
    , name : String
    , company : String
    , location : String
    , email : String
    , public_repos : Int
    , public_gists : Int
    , followers : Int
    , following : Int
    }


type alias GitHubUserRef =
    { id : Int
    , login : String
    , avatar_url : Url
    , url : Url
    , html_url : Url
    , type_ : String
    }


type alias GitHubOrganisation =
    { login : String
    , id : Int
    , node_id : String
    , url : Url
    , repos_url : Url
    , events_url : Url
    , avatar_url : Url
    , description : String
    }
