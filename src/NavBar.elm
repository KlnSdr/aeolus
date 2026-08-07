module NavBar exposing (Msg(..), navBar, unauthNavBar)

import CommonStyles exposing (buttonStyle)
import Css exposing (..)
import Html.Styled exposing (Html, a, button, div, h1, label, nav, text)
import Html.Styled.Attributes exposing (css, href)
import Html.Styled.Events exposing (onClick)
import Route exposing (Route(..))
import Users exposing (User)


type Msg
    = LogoutClicked
    | LoginClicked
    | NavElementClicked Route


type alias NavigationLocation =
    { location : Route
    , displayText : String
    }


navBarElements : List NavigationLocation
navBarElements =
    [ { location = MonthlyOverview
      , displayText = "Monatsübersicht"
      }
    , { location = YearlyOverview
      , displayText = "Jahresübersicht"
      }
    , { location = CompareYears
      , displayText = "Vergleichen"
      }
    , { location = DataQuality
      , displayText = "Datenqualität"
      }
    , { location = MonthlyOverview
      , displayText = "Monatswerte"
      }
    , { location = Route.Reports
      , displayText = "Berichte"
      }
    ]


userToName : Maybe User -> String
userToName user =
    case user of
        Just u ->
            u.displayName

        Nothing ->
            "..."


navBar : Maybe User -> Html Msg
navBar user =
    nav
        [ css navBarStyle
        ]
        [ h1 [] [ a [ css navHeadingStyle, href "/" ] [ text "Aeolus" ] ]
        , div []
            [ div [ css navBarButtonsStyle ] (List.map (\e -> button [ css buttonStyle, onClick (NavElementClicked e.location) ] [ text e.displayText ]) navBarElements)
            , div [ css navBarRight ]
                [ button [ css buttonStyle ] [ text "Nachrichten: 0" ]
                , label [] [ text ("(" ++ userToName user ++ ")") ]
                , button [ css buttonStyle, onClick LogoutClicked ] [ text "abmelden" ]
                ]
            ]
        ]


unauthNavBar : Html Msg
unauthNavBar =
    nav
        [ css navBarStyle
        ]
        [ h1 [] [ a [ css navHeadingStyle, href "/" ] [ text "Aeolus" ] ]
        , div []
            [ div [ css navBarButtonsStyle ] []
            , div [ css navBarRight ]
                [ button [ css buttonStyle, onClick LoginClicked ] [ text "anmelden" ]
                ]
            ]
        ]


navBarStyle : List Css.Style
navBarStyle =
    [ backgroundColor (hex "#00008b")
    , color (hex "#f9f9f9")
    , height (px 50)
    , displayFlex
    , alignItems center
    ]


navHeadingStyle : List Style
navHeadingStyle =
    [ display inline
    , marginLeft (px 5)
    , textDecoration none
    , color (hex "#f9f9f9")
    , active
        [ color (hex "#f9f9f9")
        ]
    ]


navBarButtonsStyle : List Style
navBarButtonsStyle =
    [ display inlineBlock
    , margin2 (px 0) (px 10)
    ]


navBarRight : List Style
navBarRight =
    [ position absolute
    , top (px 0)
    , right (px 0)
    , margin (px 12.5)
    ]
