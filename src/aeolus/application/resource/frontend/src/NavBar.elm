module NavBar exposing (Msg(..), navBar, unauthNavBar)

import CommonStyles exposing (buttonStyle)
import Css exposing (..)
import Css.Global
import Css.Media as Media exposing (only, screen, withMedia)
import FeatherIcons
import Html.Styled exposing (Html, a, button, div, fromUnstyled, h1, input, label, nav, text)
import Html.Styled.Attributes as Attributes exposing (css, for, href, id, type_)
import Html.Styled.Events exposing (onClick)
import List exposing (length)
import Messages exposing (Message)
import Route exposing (Route(..))
import String exposing (fromInt)
import Users exposing (User)


type Msg
    = LogoutClicked
    | LoginClicked
    | NavElementClicked Route
    | MessagesClicked


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
    , { location = MonthlyValues
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


navToggleId : String
navToggleId =
    "nav-toggle"


navToggleCheckbox : Html Msg
navToggleCheckbox =
    input
        [ type_ "checkbox"
        , id navToggleId
        , Attributes.class "nav-toggle-checkbox"
        , css navToggleCheckboxStyle
        ]
        []


hamburgerButton : Html Msg
hamburgerButton =
    label
        [ for navToggleId
        , css hamburgerButtonStyle
        , Attributes.attribute "aria-label" "Menü öffnen"
        ]
        [ FeatherIcons.menu |> FeatherIcons.withSize 22 |> FeatherIcons.toHtml [] |> fromUnstyled ]


navBar : Maybe User -> List Message -> Html Msg
navBar user messages =
    nav
        [ css navBarStyle
        ]
        [ div [ css navHeaderRowStyle ]
            [ h1 [] [ a [ css navHeadingStyle, href "/" ] [ text "Aeolus" ] ]
            , hamburgerButton
            ]
        , navToggleCheckbox
        , div [ Attributes.class "nav-menu", css navMenuStyle ]
            [ div [ css navBarButtonsStyle ] (List.map (\e -> button [ css (buttonStyle ++ navButtonExtraStyle), onClick (NavElementClicked e.location) ] [ text e.displayText ]) navBarElements)
            , div [ css navBarRightStyle ]
                [ button [ css (buttonStyle ++ navButtonExtraStyle), onClick MessagesClicked ] [ text ("Nachrichten: " ++ (messages |> length |> fromInt)) ]
                , label [ css navUserLabelStyle ] [ text ("(" ++ userToName user ++ ")") ]
                , button [ css (buttonStyle ++ navButtonExtraStyle), onClick LogoutClicked ] [ text "abmelden" ]
                ]
            ]
        ]


unauthNavBar : Html Msg
unauthNavBar =
    nav
        [ css navBarStyle
        ]
        [ div [ css navHeaderRowStyle ]
            [ h1 [] [ a [ css navHeadingStyle, href "/" ] [ text "Aeolus" ] ]
            ]
        , div [ css navBarRightStyle ]
            [ button [ css (buttonStyle ++ navButtonExtraStyle), onClick LoginClicked ] [ text "anmelden" ]
            ]
        ]


mobileBreakpoint : Float
mobileBreakpoint =
    960


mobileMediaQuery : List Style -> Style
mobileMediaQuery =
    withMedia [ only screen [ Media.maxWidth (px mobileBreakpoint) ] ]


navBarStyle : List Css.Style
navBarStyle =
    [ backgroundColor (hex "#00008b")
    , color (hex "#f9f9f9")
    , position relative
    , displayFlex
    , alignItems center
    , height (px 50)
    , mobileMediaQuery
        [ flexDirection column
        , alignItems stretch
        , height auto
        ]
    ]


navHeaderRowStyle : List Style
navHeaderRowStyle =
    [ displayFlex
    , alignItems center
    , justifyContent spaceBetween
    , mobileMediaQuery
        [ width (pct 100)
        , boxSizing borderBox
        , padding2 (px 4) (px 10)
        ]
    ]


hamburgerButtonStyle : List Style
hamburgerButtonStyle =
    [ display none
    , cursor pointer
    , color (hex "#f9f9f9")
    , padding (px 8)
    , mobileMediaQuery
        [ displayFlex
        , alignItems center
        ]
    ]


navToggleCheckboxStyle : List Style
navToggleCheckboxStyle =
    [ position absolute
    , opacity (num 0)
    , width (px 1)
    , height (px 1)
    , mobileMediaQuery
        [ checked
            [ Css.Global.generalSiblings
                [ Css.Global.class "nav-menu"
                    [ displayFlex
                    , flexDirection column
                    , alignItems stretch
                    ]
                ]
            ]
        ]
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


navMenuStyle : List Style
navMenuStyle =
    [ displayFlex
    , alignItems center
    , justifyContent spaceBetween
    , flexGrow (num 1)
    , mobileMediaQuery
        [ display none
        , flexDirection column
        , alignItems stretch
        , width (pct 100)
        ]
    ]


navBarButtonsStyle : List Style
navBarButtonsStyle =
    [ displayFlex
    , alignItems center
    , margin2 (px 0) (px 10)
    , mobileMediaQuery
        [ flexDirection column
        , alignItems stretch
        , margin (px 0)
        , width (pct 100)
        ]
    ]


navButtonExtraStyle : List Style
navButtonExtraStyle =
    [ mobileMediaQuery
        [ width (pct 100)
        , minHeight (px 44)
        , padding2 (px 10) (px 10)
        , fontSize (px 16)
        , textAlign left
        , boxSizing borderBox
        ]
    ]


navBarRightStyle : List Style
navBarRightStyle =
    [ displayFlex
    , alignItems center
    , margin (px 12.5)
    , marginLeft auto
    , mobileMediaQuery
        [ flexDirection column
        , alignItems stretch
        , margin (px 0)
        , padding2 (px 8) (px 10)
        , width (pct 100)
        , boxSizing borderBox
        ]
    ]


navUserLabelStyle : List Style
navUserLabelStyle =
    [ margin2 (px 0) (px 10)
    , mobileMediaQuery
        [ margin2 (px 8) (px 0)
        , textAlign left
        ]
    ]
