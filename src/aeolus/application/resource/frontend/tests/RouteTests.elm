module RouteTests exposing (suite)

import Expect
import Route exposing (Route(..), fromUrl, toPath)
import Test exposing (Test, describe, test)
import Url


allRoutes : List Route
allRoutes =
    [ Landing
    , Login
    , Signup
    , Dashboard
    , MonthlyOverview
    , YearlyOverview
    , CompareYears
    , DataQuality
    , Reports
    , MonthlyValues
    ]


urlFor : String -> Url.Url
urlFor path =
    { protocol = Url.Https
    , host = "example.com"
    , port_ = Nothing
    , path = path
    , query = Nothing
    , fragment = Nothing
    }


parsingTests : Test
parsingTests =
    describe "fromUrl parses each known path"
        [ test "/landing -> Landing" <| \_ -> fromUrl (urlFor "/landing") |> Expect.equal (Just Landing)
        , test "/login -> Login" <| \_ -> fromUrl (urlFor "/login") |> Expect.equal (Just Login)
        , test "/signup -> Signup" <| \_ -> fromUrl (urlFor "/signup") |> Expect.equal (Just Signup)
        , test "/ -> Dashboard" <| \_ -> fromUrl (urlFor "/") |> Expect.equal (Just Dashboard)
        , test "/month -> MonthlyOverview" <| \_ -> fromUrl (urlFor "/month") |> Expect.equal (Just MonthlyOverview)
        , test "/year -> YearlyOverview" <| \_ -> fromUrl (urlFor "/year") |> Expect.equal (Just YearlyOverview)
        , test "/compare -> CompareYears" <| \_ -> fromUrl (urlFor "/compare") |> Expect.equal (Just CompareYears)
        , test "/dataquality -> DataQuality" <| \_ -> fromUrl (urlFor "/dataquality") |> Expect.equal (Just DataQuality)
        , test "/reports -> Reports" <| \_ -> fromUrl (urlFor "/reports") |> Expect.equal (Just Reports)
        , test "/monthly-values -> MonthlyValues" <| \_ -> fromUrl (urlFor "/monthly-values") |> Expect.equal (Just MonthlyValues)
        , test "an unknown path parses to Nothing" <| \_ -> fromUrl (urlFor "/does-not-exist") |> Expect.equal Nothing
        ]


roundTripTests : Test
roundTripTests =
    describe "toPath / fromUrl round trip"
        (allRoutes
            |> List.map
                (\route ->
                    test ("round-trips through " ++ toPath route) <|
                        \_ ->
                            toPath route
                                |> urlFor
                                |> fromUrl
                                |> Expect.equal (Just route)
                )
        )


suite : Test
suite =
    describe "Route" [ parsingTests, roundTripTests ]
