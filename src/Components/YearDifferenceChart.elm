module Components.YearDifferenceChart exposing (temperatureBarChart)

import Chart as C
import Chart.Attributes as CA
import Css exposing (marginTop, maxHeight, maxWidth, pct, px)
import Css.Global exposing (global, selector)
import Html.Styled exposing (Html, div, fromUnstyled)
import Html.Styled.Attributes exposing (class, css)


colorFor : Float -> String
colorFor value =
    if value > 0 then
        "#d62728"

    else if value < 0 then
        "#1f77b4"

    else
        "#2ca02c"


temperatureBarChart : List { x : Float, y : Float } -> (Float -> String) -> Html msg
temperatureBarChart readings xAxisLabels =
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
                ]
                [ C.grid [ CA.color "#bbb" ]
                , C.xAxis [ CA.color "black" ]
                , C.xLabels
                    [ CA.amount 8
                    , CA.format xAxisLabels
                    , CA.color "black"
                    ]
                , C.yAxis [ CA.color "black" ]
                , C.yLabels [ CA.withGrid, CA.color "black" ]
                , C.bars
                    []
                    [ C.bar .y []
                        |> C.variation
                            (\_ d ->
                                [ CA.color (colorFor d.y) ]
                            )
                    ]
                    readings
                ]
            )
        ]
