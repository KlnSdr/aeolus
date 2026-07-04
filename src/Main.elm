module Main exposing (..)

import Browser
import Html exposing (Html, button)
import Html.Events

type alias Model = Int

type Msg =
    None
    | Increment

main: Program () Model Msg
main = Browser.element {
  init = init,
  update = update,
  view = view,
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

view : Model -> Html Msg
view model =
    button [ Html.Events.onClick Increment ] [ Html.text ("Count: " ++ String.fromInt model) ]
