module Main exposing (..)

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

type alias Model = Int

type Msg =
  None
  | Increment

main: Program () Model Msg
main =
  Browser.element {
    init = init,
    update = update,
    view = view >> toUnstyled,
    subscriptions = \_ -> Sub.none
  }

init : () -> (Model, Cmd Msg)
init _ =
  (0, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    None ->
      (model, Cmd.none)
    Increment ->
      (model + 1, Cmd.none)

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

buttonStyle: List Style
buttonStyle =
  [
    border3 (px 2) solid (hex "#00008b"),
    backgroundColor (hex "#00008b"),
    color (hex "#f9f9f9"),
    hover [
      backgroundColor (hex "#f9f9f9"),
      color (hex "#00008b")
      ]
    ]

navBarRight: List Style
navBarRight =
  [
    position absolute,
    top (px 0),
    right (px 0),
    margin (px 12.5)
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

logoStyle: List Style
logoStyle =
  [
    maxWidth (vw 25),
    maxHeight (vh 25)
    ]

landingCenterContainer: List Style
landingCenterContainer =
  [
    marginTop (vh 5),
    width (vw 50),
    marginLeft (vw 25),
    textAlign center
    ]

view : Model -> Html Msg
view model =
  div [
      css [
        margin (px 0),
        padding (px 0),
        backgroundColor (hex "#f9f9f9"),
        overflowX hidden,
        minHeight (vh 100),
        fontFamilies ["Arial", "sans-serif"]
        ]
    ]
    [
      unauthNavBar,
      div [css landingCenterContainer] [
        img [css logoStyle, src "favicon.png", alt "Aeolus"] [],
        h1 [] [text "Aeolus"]
      ]
    ]
