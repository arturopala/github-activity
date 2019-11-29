module GitHub.Model exposing (GitHubApiLimits, GitHubAuthor, GitHubCommit, GitHubCreateEventPayload, GitHubDeleteEventPayload, GitHubEvent, GitHubEventActor, GitHubEventPayload(..), GitHubEventSource(..), GitHubFailure, GitHubForkEventPayload, GitHubIssue, GitHubIssueComment, GitHubIssueCommentEventPayload, GitHubIssueLabel, GitHubIssuesEventPayload, GitHubOrganisation, GitHubPullRequest, GitHubPullRequestEventPayload, GitHubPullRequestRef, GitHubPullRequestReview, GitHubPullRequestReviewComment, GitHubPullRequestReviewCommentEventPayload, GitHubPullRequestReviewEventPayload, GitHubPushEventPayload, GitHubReference, GitHubReleaseEventPayload, GitHubReleaseRef, GitHubRepoRef, GitHubRepository, GitHubResult, GitHubSearchResult, GitHubSuccess, GitHubUser, GitHubUserRef)

import Http
import Time exposing (Posix)
import Url exposing (Url)


type alias GitHubResult =
    Result GitHubFailure GitHubSuccess


type alias GitHubSuccess =
    { url : Url
    , limits : GitHubApiLimits
    , source : String
    , metadata : Http.Metadata
    }


type alias GitHubFailure =
    { url : Url
    , cause : Http.Error
    , limits : Maybe GitHubApiLimits
    }


type alias GitHubApiLimits =
    { xRateLimit : Int
    , xRateRemaining : Int
    , xRateReset : Maybe Posix
    , xPollInterval : Int
    }


type GitHubEventSource
    = GitHubEventSourceDefault
    | GitHubEventSourceUser String
    | GitHubEventSourceOrganisation String
    | GitHubEventSourceRepository String String
    | GitHubEventSourceRepositoryById String


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
    , owner : GitHubUserRef
    , private : Bool
    , fork : Bool
    , forks_count : Int
    , watchers_count : Int
    , subscribers_count : Maybe Int
    , network_count : Maybe Int
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
    , repo : GitHubRepository
    }


type GitHubEventPayload
    = GitHubPullRequestEvent GitHubPullRequestEventPayload
    | GitHubPullRequestReviewEvent GitHubPullRequestReviewEventPayload
    | GitHubPullRequestReviewCommentEvent GitHubPullRequestReviewCommentEventPayload
    | GitHubReleaseEvent GitHubReleaseEventPayload
    | GitHubPushEvent GitHubPushEventPayload
    | GitHubIssuesEvent GitHubIssuesEventPayload
    | GitHubIssueCommentEvent GitHubIssueCommentEventPayload
    | GitHubCreateEvent GitHubCreateEventPayload
    | GitHubDeleteEvent GitHubDeleteEventPayload
    | GitHubForkEvent GitHubForkEventPayload
    | GitHubWatchEvent
    | GitHubOtherEvent


type alias GitHubPullRequestEventPayload =
    { action : String
    , number : Int
    , pull_request : GitHubPullRequest
    }


type alias GitHubPullRequestReviewEventPayload =
    { action : String
    , review : GitHubPullRequestReview
    , pull_request : GitHubPullRequestRef
    }


type alias GitHubPullRequestReviewCommentEventPayload =
    { action : String
    , comment : GitHubPullRequestReviewComment
    , pull_request : GitHubPullRequestRef
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
    , body : Maybe String
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
    , number : Int
    }


type alias GitHubPullRequestRef =
    { id : Int
    , url : Url
    , html_url : Url
    , state : String
    , title : String
    , body : Maybe String
    , created_at : Posix
    , merged_at : Maybe Posix
    , user : GitHubUserRef
    , number : Int
    }


type alias GitHubPullRequestReview =
    { id : Int
    , user : GitHubUserRef
    , body : Maybe String
    , commit_id : String
    , submitted_at : Posix
    , state : String
    , author_association : String
    , pull_request_url : Url
    }


type alias GitHubPullRequestReviewComment =
    { id : Int
    , pull_request_review_id : Int
    , user : GitHubUserRef
    , body : Maybe String
    , commit_id : String
    , created_at : Posix
    , author_association : String
    , url : Url
    , html_url : Url
    , pull_request_url : Url
    , path : String
    , diff_hunk : String
    }


type alias GitHubReleaseEventPayload =
    { action : String
    , release : GitHubReleaseRef
    }


type alias GitHubPushEventPayload =
    { ref : String
    , head : String
    , before : String
    , size : Int
    , distinct_size : Int
    , commits : List GitHubCommit
    }


type alias GitHubIssuesEventPayload =
    { action : String
    , issue : GitHubIssue
    }


type alias GitHubIssueCommentEventPayload =
    { action : String
    , issue : GitHubIssue
    , comment : GitHubIssueComment
    }


type alias GitHubCreateEventPayload =
    { ref_type : String
    , ref : String
    , master_branch : String
    , description : Maybe String
    , pusher_type : String
    }


type alias GitHubDeleteEventPayload =
    { ref_type : String
    , ref : String
    , pusher_type : String
    }


type alias GitHubForkEventPayload =
    { forkee : GitHubRepository
    }


type alias GitHubCommit =
    { sha : String
    , message : String
    , author : GitHubAuthor
    , url : Url
    , distinct : Bool
    }


type alias GitHubAuthor =
    { name : String
    , email : String
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


type alias GitHubSearchResult a =
    { total_count : Int
    , incomplete_results : Bool
    , items : List a
    }


type alias GitHubIssue =
    { id : Int
    , url : Url
    , html_url : Url
    , title : String
    , user : GitHubUserRef
    , labels : List GitHubIssueLabel
    , state : String
    , number : Int
    }


type alias GitHubIssueLabel =
    { id : Int
    , name : String
    , color : String
    , url : Url
    }


type alias GitHubIssueComment =
    { id : Int
    , user : GitHubUserRef
    , body : Maybe String
    , created_at : Posix
    , author_association : String
    , url : Url
    , html_url : Url
    }
