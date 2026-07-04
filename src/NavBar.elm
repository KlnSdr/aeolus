module NavBar exposing (navBar, unauthNavBar)

import Browser
import Css exposing (..)
import Html.Styled exposing (Html, div, nav, text, toUnstyled)
import Html.Styled.Attributes exposing (css)
import Html.Styled exposing (h1)
import Html.Styled.Attributes exposing (id)
import Html.Styled exposing (button)
import Html.Styled exposing (label)
import Html.Styled exposing (img)
import Html.Styled.Attributes exposing (src)
import Html.Styled.Attributes exposing (alt)
import Types exposing (Msg)
import CommonStyles exposing (buttonStyle)

type alias NavigationLocation =
  {
    location: String,
    displayText: String
  }

navBarElements: List NavigationLocation
navBarElements =
  [
    {
      location = "{{CONTEXT}}/month",
      displayText = "Monatsübersicht"
    },
    {
      location = "{CONTEXT}}/year",
      displayText = "Jahresübersicht"
    },
    {
      location = "{CONTEXT}}/compare",
      displayText = "Vergleichen"
    },
    {
      location = "{CONTEXT}}/dataquality",
      displayText = "Datenqualität"
    },
    {
      location = "{CONTEXT}}/monthly-values",
      displayText = "Monatswerte"
    },
    {
      location = "{CONTEXT}}/reports",
      displayText = "Berichte"
    },
    {
      location = "{CONTEXT}}/blanket",
      displayText = "Temperaturdecke"
    }
    ]

navBar: Html Msg
navBar =
  nav [
    css navBarStyle
    ]
    [
      h1 [css navHeadingStyle] [text "Aeolus"],
      div [ ] [
        div [css navBarButtonsStyle] (List.map (\e -> (button [css buttonStyle] [text e.displayText]))  navBarElements),
        div [css navBarRight] [
          button [css buttonStyle] [text "Nachrichten: 0"],
          label [] [text "(...)"],
          button [css buttonStyle] [text "logout"]
          ]
        ]
      ]

-- TODO combine with navBar
unauthNavBar: Html Msg
unauthNavBar =
  nav [
    css navBarStyle
    ]
    [
      h1 [css navHeadingStyle] [text "Aeolus"],
      div [ ] [
        div [css navBarButtonsStyle] [],
        div [css navBarRight] [
          button [css buttonStyle] [text "anmelden"]
          ]
        ]
      ]

navBarStyle : List Css.Style
navBarStyle =
  [
    backgroundColor (hex "#00008b"),
    color (hex "#f9f9f9"),
    height (px 50),
    displayFlex,
    alignItems center
    ]

navHeadingStyle: List Style
navHeadingStyle =
  [
    display inline,
    marginLeft (px 5),
    textDecoration none,
    color (hex "#f9f9f9")
    ]

navBarButtonsStyle: List Style
navBarButtonsStyle =
  [
    display inlineBlock,
    margin2 (px 0) (px 10)
    ]

navBarRight: List Style
navBarRight =
  [
    position absolute,
    top (px 0),
    right (px 0),
    margin (px 12.5)
    ]

