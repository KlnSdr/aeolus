module Components.Stats exposing (..)

import Css exposing (property, textAlign)
import Html.Styled exposing (Html, div, h2, h3, p, text)
import Html.Styled.Attributes exposing (css)
import List exposing (length, map, sum)
import List.Extra exposing (maximumWith, minimumWith)
import Readings exposing (Reading)
import Round


readingStats : List Reading -> Html msg
readingStats readings =
    let
        min =
            case minimumWith (\a b -> compare a.value b.value) readings of
                Just val ->
                    val

                Nothing ->
                    { value = 0.0, date = "1990-01-01" }

        max =
            case maximumWith (\a b -> compare a.value b.value) readings of
                Just val ->
                    val

                Nothing ->
                    { value = 0.0, date = "1990-01-01" }

        avg =
            (readings |> map (\a -> a.value) |> sum) / (readings |> length |> toFloat)
    in
    div
        [ css
            [ textAlign Css.left
            ]
        ]
        [ h2 [] [ text "Statistiken" ]
        , div
            [ css
                [ property "display" "grid"
                , property "grid-template-columns" "repeat(3, 1fr)"
                , property "grid-template-rows" "repeat(1, 1fr)"
                , property "grid-column-gap" "5px"
                , property "grid-row-gap" "5px"
                ]
            ]
            [ statsBlock "Maximaltemperatur" (Round.round 1 max.value) max.date
            , statsBlock "Minimaltemperatur" (Round.round 1 min.value) min.date
            , statsBlockNoDate "Durchschnittstemperatur" (Round.round 1 avg)
            ]
        ]


statsBlock : String -> String -> String -> Html msg
statsBlock heading value date =
    div []
        [ h3 [] [ text heading ]
        , p [] [ text value ]
        , p [] [ text date ]
        ]


statsBlockNoDate : String -> String -> Html msg
statsBlockNoDate heading value =
    statsBlock heading value ""
