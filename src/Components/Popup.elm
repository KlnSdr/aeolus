module Components.Popup exposing
    ( Model
    , Msg(..)
    , closed
    , open
    , update
    , view
    )

import Css exposing (..)
import Html.Styled exposing (Html, button, div, text)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (onClick, stopPropagationOn)
import Json.Decode as Decode
import CommonStyles exposing (buttonStyle)


type Model contentMsg
    = Closed
    | Open (Html contentMsg)


closed : Model contentMsg
closed =
    Closed


open : Html contentMsg -> Model contentMsg
open content =
    Open content


type Msg contentMsg
    = ClickedBackground
    | ClickedClose
    | ContentMsg contentMsg
    | NoOp


update : Msg contentMsg -> Model contentMsg -> Model contentMsg
update msg model =
    case msg of
        ClickedBackground ->
            Closed

        ClickedClose ->
            Closed

        NoOp ->
            model

        ContentMsg _ ->
            model


view : Model contentMsg -> Html (Msg contentMsg)
view model =
    case model of
        Closed ->
            text ""

        Open content ->
            div
                [ css popupBackgroundStyle
                , onClick ClickedBackground
                ]
                [ div
                    [ css popupStyle
                    , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
                    ]
                    [ button [ css buttonStyle, onClick ClickedClose ] [ text "X" ]
                    , div [ css contentStyle ] [ Html.Styled.map ContentMsg content ]
                    ]
                ]


popupBackgroundStyle : List Style
popupBackgroundStyle =
    [ position fixed
    , top (px 0)
    , left (px 0)
    , width (pct 100)
    , height (pct 100)
    , backgroundColor (rgba 0 0 0 0.5)
    , displayFlex
    , alignItems center
    , justifyContent center
    , property "z-index" "1000"
    ]


popupStyle : List Style
popupStyle =
    [ position relative
    , backgroundColor (hex "#f9f9f9")
    , padding (px 20)
    , borderRadius (px 4)
    , minWidth (px 300)
    , maxWidth (pct 90)
    , maxHeight (pct 90)
    , overflowY auto
    ]


contentStyle : List Style
contentStyle =
    [ marginTop (px 20) ]
