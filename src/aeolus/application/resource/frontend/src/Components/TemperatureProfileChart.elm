module Components.TemperatureProfileChart exposing (Model, Msg, init, update, view)

import Chart as C
import Chart.Attributes as CA
import Chart.Events as CE
import Chart.Item as CI
import Css exposing (marginTop, maxHeight, maxWidth, pct, px)
import Css.Global exposing (global, selector)
import Html
import Html.Styled exposing (Html, div, fromUnstyled)
import Html.Styled.Attributes exposing (class, css)


type alias Point =
    { x : Float, y : Float }


type alias Model =
    { hovering : List (CI.One Point CI.Dot)
    }


init : Model
init =
    { hovering = [] }


type Msg
    = OnHover (List (CI.One Point CI.Dot))


update : Msg -> Model -> Model
update (OnHover hovering) model =
    { model | hovering = hovering }


view :
    { points : List Point
    , xAxisLabel : Float -> String
    , tooltipLines : Float -> Float -> List String
    }
    -> Model
    -> Html Msg
view config model =
    div
        [ class "chart-widget"
        , css [ marginTop (px 50) ]
        ]
        [ global
            [ selector ".chart-widget svg"
                [ maxWidth (pct 100)
                , maxHeight (pct 100)
                , Css.property "display" "block"
                ]
            ]
        , fromUnstyled
            (C.chart
                [ CA.height 450
                , CA.width 800
                , CA.padding { top = 10, bottom = 5, left = 10, right = 10 }
                , CE.onMouseMove OnHover (CE.getNearest CI.dots)
                , CE.onMouseLeave (OnHover [])
                ]
                [ C.grid [ CA.color "#bbb" ]
                , C.xAxis [ CA.color "black" ]
                , C.xLabels
                    [ CA.amount 8
                    , CA.format config.xAxisLabel
                    , CA.color "black"
                    ]
                , C.yAxis [ CA.color "black" ]
                , C.yLabels [ CA.withGrid, CA.color "black" ]
                , C.series .x
                    [ C.interpolated .y [ CA.monotone, CA.color "#00008b" ] [ CA.circle ]
                    ]
                    config.points
                , C.each model.hovering <|
                    \_ item ->
                        [ C.tooltip item
                            []
                            []
                            (config.tooltipLines (CI.getX item) (CI.getY item)
                                |> List.map Html.text
                            )
                        ]
                ]
            )
        ]
