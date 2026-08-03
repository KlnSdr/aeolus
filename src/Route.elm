module Route exposing (Route(..), fromUrl, toPath)

import Url exposing (Url)
import Url.Parser as Parser exposing (Parser, oneOf, s, top)


type Route
    = Landing
    | Login
    | Signup
    | Dashboard
    | MonthlyOverview
    | YearlyOverview
    | CompareYears


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Landing (s "landing")
        , Parser.map Login (s "login")
        , Parser.map Signup (s "signup")
        , Parser.map MonthlyOverview (s "month")
        , Parser.map YearlyOverview (s "year")
        , Parser.map CompareYears (s "compare")
        , Parser.map Dashboard top
        ]


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


toPath : Route -> String
toPath route =
    case route of
        Landing ->
            "/landing"

        Login ->
            "/login"

        Signup ->
            "/signup"

        Dashboard ->
            "/"

        MonthlyOverview ->
            "/month"

        YearlyOverview ->
            "/year"

        CompareYears ->
            "/compare"
