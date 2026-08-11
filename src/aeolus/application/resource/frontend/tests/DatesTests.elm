module DatesTests exposing (suite)

import Dates exposing (elmMonthToInt, formatEpochMillis, formatRataDie, fromRataDie, parseDateToRataDie, toRataDie)
import Expect
import Test exposing (Test, describe, test)
import Time exposing (Month(..))


suite : Test
suite =
    describe "Dates"
        [ describe "toRataDie / fromRataDie round trip"
            [ test "a normal date" <|
                \_ ->
                    toRataDie 2024 3 15
                        |> fromRataDie
                        |> Expect.equal { year = 2024, month = 3, day = 15 }
            , test "Jan 1 of a leap year" <|
                \_ ->
                    toRataDie 2024 1 1
                        |> fromRataDie
                        |> Expect.equal { year = 2024, month = 1, day = 1 }
            , test "Feb 29 on a leap year" <|
                \_ ->
                    toRataDie 2024 2 29
                        |> fromRataDie
                        |> Expect.equal { year = 2024, month = 2, day = 29 }
            , test "Dec 31 rolls correctly into the next year" <|
                \_ ->
                    toRataDie 2023 12 31
                        |> fromRataDie
                        |> Expect.equal { year = 2023, month = 12, day = 31 }
            , test "a date before a non-leap century year (1900)" <|
                \_ ->
                    toRataDie 1900 2 28
                        |> fromRataDie
                        |> Expect.equal { year = 1900, month = 2, day = 28 }
            , test "a date in the far past" <|
                \_ ->
                    toRataDie 1970 1 1
                        |> fromRataDie
                        |> Expect.equal { year = 1970, month = 1, day = 1 }
            ]
        , describe "toRataDie is a stable, increasing day count"
            [ test "consecutive days differ by exactly 1" <|
                \_ ->
                    (toRataDie 2024 2 29 - toRataDie 2024 2 28)
                        |> Expect.equal 1
            , test "Mar 1 is one day after Feb 29 on a leap year" <|
                \_ ->
                    (toRataDie 2024 3 1 - toRataDie 2024 2 29)
                        |> Expect.equal 1
            , test "Mar 1 is one day after Feb 28 on a non-leap year" <|
                \_ ->
                    (toRataDie 2023 3 1 - toRataDie 2023 2 28)
                        |> Expect.equal 1
            ]
        , describe "parseDateToRataDie"
            [ test "parses a well-formed ISO date" <|
                \_ ->
                    parseDateToRataDie "2024-03-15"
                        |> Expect.equal (Just (toRataDie 2024 3 15))
            , test "rejects a date missing a component" <|
                \_ ->
                    parseDateToRataDie "2024-03"
                        |> Expect.equal Nothing
            , test "rejects a non-numeric date" <|
                \_ ->
                    parseDateToRataDie "abcd-ef-gh"
                        |> Expect.equal Nothing
            , test "rejects an empty string" <|
                \_ ->
                    parseDateToRataDie ""
                        |> Expect.equal Nothing
            ]
        , describe "formatRataDie"
            [ test "pads single-digit day and month" <|
                \_ ->
                    toRataDie 2024 3 5
                        |> formatRataDie
                        |> Expect.equal "05.03"
            , test "does not pad double-digit day and month" <|
                \_ ->
                    toRataDie 2024 12 25
                        |> formatRataDie
                        |> Expect.equal "25.12"
            ]
        , describe "formatEpochMillis"
            [ test "formats a known epoch-millis timestamp" <|
                \_ ->
                    -- 1970-01-01 00:00:00 UTC
                    formatEpochMillis "0"
                        |> Expect.equal "01.01.1970"
            , test "formats a timestamp exactly one day later" <|
                \_ ->
                    formatEpochMillis (String.fromInt 86400000)
                        |> Expect.equal "02.01.1970"
            , test "returns a placeholder for non-numeric input" <|
                \_ ->
                    formatEpochMillis "not-a-number"
                        |> Expect.equal "-"
            ]
        , describe "elmMonthToInt"
            [ test "January is 1" <| \_ -> elmMonthToInt Jan |> Expect.equal 1
            , test "June is 6" <| \_ -> elmMonthToInt Jun |> Expect.equal 6
            , test "December is 12" <| \_ -> elmMonthToInt Dec |> Expect.equal 12
            ]
        ]
