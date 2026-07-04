module MainView exposing (..)
import Types exposing (Model)
import Html.Styled exposing (Html)
import Types exposing (Msg)
import Html.Styled exposing (div)
import Html.Styled exposing (h1)
import Types exposing (LastReading)
import Html.Styled exposing (text)
import Html.Styled exposing (p)
import Round

getLastReadingValue: Maybe LastReading -> String
getLastReadingValue lastReading =
  case lastReading of
    Just val -> (Round.round 1 val.value) ++ " °C"
    Nothing -> "XY.Z °C"

getLastReadingDate: Maybe LastReading -> String
getLastReadingDate lastReading =
  case lastReading of
    Just val -> val.date
    Nothing -> "DD.MM.YYYY"

mainView: Model -> List (Html Msg)
mainView model =
  [
    div [] [
      h1 [] [text (getLastReadingValue model.lastReading)],
      p [] [text ("vom: " ++ (getLastReadingDate model.lastReading))]

      ]
    ]
