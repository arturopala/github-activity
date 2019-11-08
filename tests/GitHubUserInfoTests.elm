module GitHubUserInfoTests exposing (all)

import Expect exposing (Expectation)
import GitHub.Decode
import Json.Decode exposing (decodeString, errorToString)
import Test exposing (..)
import TestUtil exposing (..)
import Url


all : Test
all =
    describe "decodeGitHubUserInfo should"
        [ test "decode valid GitHub user json" <|
            \() ->
                let
                    underTest =
                        decodeString GitHub.Decode.decodeGitHubUserInfo
                            """{
                                     "login": "octocat",
                                     "id": 1,
                                     "node_id": "MDQ6VXNlcjE=",
                                     "avatar_url": "https://github.com/images/error/octocat_happy.gif",
                                     "gravatar_id": "",
                                     "url": "https://api.github.com/users/octocat",
                                     "html_url": "https://github.com/octocat",
                                     "followers_url": "https://api.github.com/users/octocat/followers",
                                     "following_url": "https://api.github.com/users/octocat/following{/other_user}",
                                     "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
                                     "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
                                     "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
                                     "organizations_url": "https://api.github.com/users/octocat/orgs",
                                     "repos_url": "https://api.github.com/users/octocat/repos",
                                     "events_url": "https://api.github.com/users/octocat/events{/privacy}",
                                     "received_events_url": "https://api.github.com/users/octocat/received_events",
                                     "type": "User",
                                     "site_admin": false,
                                     "name": "monalisa octocat",
                                     "company": "GitHub",
                                     "blog": "https://github.com/blog",
                                     "location": "San Francisco",
                                     "email": "octocat@github.com",
                                     "hireable": false,
                                     "bio": "There once was...",
                                     "public_repos": 2,
                                     "public_gists": 1,
                                     "followers": 20,
                                     "following": 0,
                                     "created_at": "2008-01-14T04:33:35Z",
                                     "updated_at": "2008-01-14T04:33:35Z"
                                   }"""
                in
                underTest
                    |> Expect.all
                        [ expectOk errorToString
                            [ having .login (Expect.equal "octocat")
                            , having .name (Expect.equal "monalisa octocat")
                            , having .company (Expect.equal "GitHub")
                            , having .public_repos (Expect.equal 2)
                            , having .public_gists (Expect.equal 1)
                            , having .followers (Expect.equal 20)
                            , having .following (Expect.equal 0)
                            , having .url (having Url.toString (Expect.equal "https://api.github.com/users/octocat"))
                            , having .events_url (having Url.toString (Expect.equal "https://api.github.com/users/octocat/events"))
                            ]
                        ]
        ]
