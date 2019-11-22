module GitHub.Authorization exposing (Authorization(..))


type Authorization
    = Unauthorized
    | Token String String
