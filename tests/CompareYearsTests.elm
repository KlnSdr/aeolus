module CompareYearsTests exposing (suite)

import Expect
import Pages.CompareYears exposing (differenceByDay, monthDay)
import Readings exposing (Reading)
import Test exposing (Test, describe, test)


monthDayTests : Test
monthDayTests =
    describe "monthDay"
        [ test "drops the year prefix from an ISO date" <|
            \_ -> monthDay "2024-03-15" |> Expect.equal "03-15"
        , test "works for a date in January" <|
            \_ -> monthDay "2019-01-01" |> Expect.equal "01-01"
        , test "produces the same month-day for the same calendar day in different years" <|
            \_ -> monthDay "2020-07-04" |> Expect.equal (monthDay "1999-07-04")
        ]


reading : String -> Float -> Reading
reading date value =
    { date = date, value = value }


differenceByDayTests : Test
differenceByDayTests =
    describe "differenceByDay"
        [ test "computes value1 - value2 for matching calendar days" <|
            \_ ->
                differenceByDay
                    [ reading "2024-03-15" 20.0 ]
                    [ reading "2023-03-15" 15.0 ]
                    |> Expect.equal [ { date = "2024-03-15", value = 5.0 } ]
        , test "produces a negative difference when year2 was warmer" <|
            \_ ->
                differenceByDay
                    [ reading "2024-03-15" 10.0 ]
                    [ reading "2023-03-15" 15.0 ]
                    |> Expect.equal [ { date = "2024-03-15", value = -5.0 } ]
        , test "skips days present in year1 but missing from year2" <|
            \_ ->
                differenceByDay
                    [ reading "2024-03-15" 20.0, reading "2024-03-16" 21.0 ]
                    [ reading "2023-03-15" 15.0 ]
                    |> Expect.equal [ { date = "2024-03-15", value = 5.0 } ]
        , test "ignores extra days only present in year2" <|
            \_ ->
                differenceByDay
                    [ reading "2024-03-15" 20.0 ]
                    [ reading "2023-03-15" 15.0, reading "2023-03-16" 16.0 ]
                    |> Expect.equal [ { date = "2024-03-15", value = 5.0 } ]
        , test "matches days across years by month-day, ignoring the year itself" <|
            \_ ->
                differenceByDay
                    [ reading "2024-12-25" 5.0 ]
                    [ reading "1999-12-25" 2.0 ]
                    |> Expect.equal [ { date = "2024-12-25", value = 3.0 } ]
        , test "returns an empty list when there is no overlap" <|
            \_ ->
                differenceByDay
                    [ reading "2024-03-15" 20.0 ]
                    [ reading "2023-04-01" 15.0 ]
                    |> Expect.equal []
        , test "returns an empty list for two empty inputs" <|
            \_ -> differenceByDay [] [] |> Expect.equal []
        ]


suite : Test
suite =
    describe "Pages.CompareYears" [ monthDayTests, differenceByDayTests ]
