module Main exposing (..)

import Browser
import Css exposing (..)
import Html.Styled exposing (Html, div, text, toUnstyled)
import Html.Styled.Attributes exposing (css)
import Html.Styled exposing (h1)
import Html.Styled exposing (img)
import Html.Styled.Attributes exposing (src)
import Html.Styled.Attributes exposing (alt)
import Types exposing (..)
import NavBar exposing (unauthNavBar)

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
