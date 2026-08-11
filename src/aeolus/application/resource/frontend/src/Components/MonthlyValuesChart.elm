module Components.MonthlyValuesChart exposing (Point, view)

import Chart as C
import Chart.Attributes as CA
import Css exposing (alignItems, backgroundColor, center, displayFlex, hex, marginTop, maxHeight, maxWidth, pct, property, px, width)
import Css.Global exposing (global, selector)
import Html.Styled exposing (Html, div, fromUnstyled, span, text)
import Html.Styled.Attributes exposing (class, css)
import List.Extra


type alias Point =
    { index : Float
    , label : String
    , highTariffPower : Float
    , lowTariffPower : Float
    , householdPower : Float
    , operatingHoursHeating : Float
    , operatingHoursWater : Float
    }


labelAt : List Point -> Float -> String
labelAt points x =
    points
        |> List.Extra.getAt (round x - 1)
        |> Maybe.map .label
        |> Maybe.withDefault ""


view : List Point -> Html msg
view points =
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
                    [ CA.amount (List.length points)
                    , CA.format (labelAt points)
                    , CA.color "black"
                    ]
                , C.yAxis [ CA.color "black" ]
                , C.yLabels [ CA.withGrid, CA.color "black" ]
                , C.bars
                    []
                    [ C.stacked
                        [ C.bar .operatingHoursHeating [ CA.color "#666699" ]
                        , C.bar .operatingHoursWater [ CA.color "#668399" ]
                        ]
                    ]
                    points
                , C.series .index
                    [ C.interpolated .highTariffPower [ CA.monotone, CA.color "#0000ff" ] []
                    , C.interpolated .lowTariffPower [ CA.monotone, CA.color "#00ccff" ] []
                    , C.interpolated .householdPower [ CA.monotone, CA.color "#ff6600" ] []
                    ]
                    points
                ]
            )
        , legend
        ]


legend : Html msg
legend =
    div
        [ css
            [ displayFlex
            , property "gap" "15px"
            , property "flex-wrap" "wrap"
            , marginTop (px 10)
            ]
        ]
        [ legendItem "#0000ff" "Hochtarifstrom"
        , legendItem "#00ccff" "Niedrigtarifstrom"
        , legendItem "#ff6600" "Hausstrom"
        , legendItem "#666699" "Betriebsstunden Heizung"
        , legendItem "#668399" "Betriebsstunden Wasser"
        ]


legendItem : String -> String -> Html msg
legendItem color label =
    div [ css [ displayFlex, alignItems center, property "gap" "5px" ] ]
        [ span
            [ css
                [ width (px 12)
                , Css.height (px 12)
                , backgroundColor (hex (String.dropLeft 1 color))
                , Css.display Css.inlineBlock
                ]
            ]
            []
        , text label
        ]
