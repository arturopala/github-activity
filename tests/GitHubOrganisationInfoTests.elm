module GitHubOrganisationInfoTests exposing (all)

import Expect exposing (Expectation)
import GitHub.Decode
import Json.Decode exposing (decodeString, errorToString)
import Test exposing (..)
import TestUtil exposing (..)
import Url


all : Test
all =
    describe "decodeGitHubOrganisationInfo should"
        [ test "decode valid GitHub organisation json" <|
            \() ->
                let
                    underTest =
                        decodeString GitHub.Decode.decodeOrganisation
                            """{
                                   "login": "github",
                                   "id": 1,
                                   "node_id": "MDEyOk9yZ2FuaXphdGlvbjE=",
                                   "url": "https://api.github.com/orgs/github",
                                   "repos_url": "https://api.github.com/orgs/github/repos",
                                   "events_url": "https://api.github.com/orgs/github/events",
                                   "hooks_url": "https://api.github.com/orgs/github/hooks",
                                   "issues_url": "https://api.github.com/orgs/github/issues",
                                   "members_url": "https://api.github.com/orgs/github/members{/member}",
                                   "public_members_url": "https://api.github.com/orgs/github/public_members{/member}",
                                   "avatar_url": "https://github.com/images/error/octocat_happy.gif",
                                   "description": "A great organization"
                                 }"""
                in
                underTest
                    |> Expect.all
                        [ expectOk errorToString
                            [ having .login (Expect.equal "github")
                            , having .id (Expect.equal 1)
                            , having .node_id (Expect.equal "MDEyOk9yZ2FuaXphdGlvbjE=")
                            , having .url (having Url.toString (Expect.equal "https://api.github.com/orgs/github"))
                            , having .events_url (having Url.toString (Expect.equal "https://api.github.com/orgs/github/events"))
                            , having .repos_url (having Url.toString (Expect.equal "https://api.github.com/orgs/github/repos"))
                            , having .avatar_url (having Url.toString (Expect.equal "https://github.com/images/error/octocat_happy.gif"))
                            , having .description (Expect.equal "A great organization")
                            ]
                        ]
        ]
