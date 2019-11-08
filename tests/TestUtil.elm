module TestUtil exposing (expectOk, having)

import Expect exposing (Expectation, fail, pass)


expectOk : (a -> String) -> List (b -> Expectation) -> Result a b -> Expectation
expectOk toString expectations result =
    case result of
        Ok r ->
            if List.isEmpty expectations then
                pass

            else
                r |> Expect.all expectations

        Err e ->
            fail (toString e)


having : (a -> b) -> (b -> Expectation) -> a -> Expectation
having get expectation =
    \v -> expectation (get v)
