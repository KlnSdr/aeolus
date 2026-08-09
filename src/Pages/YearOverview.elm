module Pages.YearOverview exposing (Model, Msg, init, update, view)

import CommonStyles exposing (buttonStyle)
import Components.Stats exposing (readingStats)
import Components.TemperatureProfileChart as Chart
import Css exposing (backgroundColor, center, color, hex, hover, margin, marginTop, pct, property, px, textAlign, width)
import Dates exposing (formatRataDie, parseDateToRataDie)
import FeatherIcons exposing (download, toHtml)
import File.Download as Download
import Html.Styled exposing (Html, button, div, fromUnstyled, map, option, p, select, table, td, text, th, tr)
import Html.Styled.Attributes exposing (css, value)
import Html.Styled.Events exposing (onClick, onInput)
import Http
import List exposing (reverse)
import Readings exposing (Reading)
import RemoteData exposing (RemoteData(..), WebData)
import Round
import String exposing (fromInt, toInt)
import Users exposing (User)
import Css exposing (overflow)
import Css exposing (scroll)
import Css exposing (maxHeight)
import Css exposing (vh)
import Css exposing (display)
import Css exposing (block)


type alias Model =
    { user : WebData User
    , readings : WebData (List Reading)
    , chart : Chart.Model
    , year : Int
    }


init : ( Model, Cmd Msg )
init =
    ( { user = Loading, readings = NotAsked, chart = Chart.init, year = 2026 }
    , Users.info UserResponded
    )


type SelectElement
    = Year


type Msg
    = UserResponded (Result Http.Error User)
    | ReadingResponded (Result Http.Error (List Reading))
    | ChartMsg Chart.Msg
    | LoadReadings Int
    | SelectChanged SelectElement String
    | DownloadReadingsAsCSV
    | CsvData (Result Http.Error String)


toInt : String -> Int -> Int
toInt str default =
    case str |> String.toInt of
        Just val ->
            val

        Nothing ->
            default


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserResponded result ->
            ( Users.handleResponse result model
            , case result of
                Ok _ ->
                    Readings.forYear ReadingResponded model.year

                Err _ ->
                    Cmd.none
            )

        ReadingResponded result ->
            ( { model | readings = RemoteData.fromResult result }, Cmd.none )

        LoadReadings year ->
            ( model, Readings.forYear ReadingResponded year )

        ChartMsg subMsg ->
            ( { model | chart = Chart.update subMsg model.chart }, Cmd.none )

        SelectChanged selectType value ->
            case selectType of
                Year ->
                    ( { model | year = toInt value 0 }, Readings.forYear ReadingResponded (toInt value 0) )

        DownloadReadingsAsCSV ->
            ( model, Readings.downloadCsvForYear CsvData model.year )

        CsvData (Ok csv) ->
            ( model, Download.string "readings.csv" "text/csv" csv )

        CsvData (Err _) ->
            ( model, Cmd.none )


view : Model -> List (Html Msg)
view model =
    [ div
        [ css
            [ property "display" "grid"
            , property "grid-template-columns" "3fr 1fr"
            , property "grid-template-rows" "1fr"
            , property "grid-column-gap" "5px"
            , property "grid-row-gap" "5px"
            , width (pct 60)
            , margin Css.auto
            , marginTop (px 50)
            , textAlign center
            ]
        ]
        [ div
            [ css
                [ Css.property "aspect-ratio" "2 / 1"
                ]
            ]
            ([ select [ value (model.year |> fromInt), onInput (SelectChanged Year) ]
                (List.range 2000 2026 |> reverse |> List.map (\e -> option [] [ text (fromInt e) ]))
             , button [ css buttonStyle, onClick DownloadReadingsAsCSV ] [ download |> FeatherIcons.withSize 12 |> toHtml [] |> fromUnstyled, text " herunterladen" ]
             ]
                ++ (case model.readings of
                        NotAsked ->
                            [ p [] [ text "Loading..." ] ]

                        Loading ->
                            [ p [] [ text "Loading..." ] ]

                        Failure _ ->
                            [ p [] [ text "Couldn't load readings." ] ]

                        Success readings ->
                            [ renderChart readings model, readingStats readings ]
                   )
            )
        , case model.readings of
            Success readings ->
                valuesTable readings

            _ ->
                valuesTable []
        ]
    ]


valuesTable : List Reading -> Html Msg
valuesTable readings =
    table [css [overflow scroll, maxHeight (vh 80), display block]]
        (tr []
            [ th [] [ text "Datum" ]
            , th [] [ text "Temperatur" ]
            ]
            :: (readings
                    |> List.map
                        (\r ->
                            tr
                                [ css
                                    [ hover
                                        [ backgroundColor (hex "#00008b")
                                        , color (hex "#f9f9f9")
                                        ]
                                    ]
                                ]
                                [ td [] [ r.date |> text ]
                                , td [] [ r.value |> Round.round 2 |> text ]
                                ]
                        )
               )
        )


renderChart : List Reading -> Model -> Html Msg
renderChart readings model =
    let
        points =
            readings
                |> List.filterMap
                    (\reading ->
                        parseDateToRataDie reading.date
                            |> Maybe.map (\rd -> { x = toFloat rd, y = reading.value })
                    )
    in
    map ChartMsg
        (Chart.view
            { points = points
            , xAxisLabel = \x -> formatRataDie (round x)
            , tooltipLines =
                \x y ->
                    [ formatRataDie (round x) ++ ": "
                    , Round.round 1 y ++ " °C"
                    ]
            }
            model.chart
        )
