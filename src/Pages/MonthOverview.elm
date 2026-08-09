module Pages.MonthOverview exposing (Model, Msg, init, update, view)

import CommonStyles exposing (buttonStyle)
import Components.Stats exposing (readingStats)
import Components.TemperatureProfileChart as Chart
import Constants exposing (intToMonth, monthToInt, months)
import Css exposing (auto, backgroundColor, center, color, hex, hover, margin, marginTop, pct, property, px, textAlign, width)
import Dates exposing (elmMonthToInt, formatRataDie, getCurrentTime, parseDateToRataDie)
import FeatherIcons exposing (download, toHtml)
import File.Download as Download
import Html.Styled exposing (Html, button, div, fromUnstyled, option, p, select, table, td, text, th, tr)
import Html.Styled.Attributes exposing (css, value)
import Html.Styled.Events exposing (onClick, onInput)
import Http
import List exposing (reverse)
import Messages exposing (Message, getAllMessages)
import Readings exposing (Reading)
import RemoteData exposing (RemoteData(..), WebData)
import Round
import String exposing (fromInt, toInt)
import Time exposing (toMonth, toYear, utc)
import Users exposing (User)


type alias Model =
    { user : WebData User
    , readings : WebData (List Reading)
    , chart : Chart.Model
    , year : Int
    , month : Int
    , messages : WebData (List Message)
    }


init : ( Model, Cmd Msg )
init =
    ( { user = Loading
      , readings = NotAsked
      , chart = Chart.init
      , year = 2026
      , month = 1
      , messages = NotAsked
      }
    , Users.info UserResponded
    )


type SelectElement
    = Year
    | Month


type Msg
    = UserResponded (Result Http.Error User)
    | ReadingResponded (Result Http.Error (List Reading))
    | ChartMsg Chart.Msg
    | LoadReadings Int Int
    | SelectChanged SelectElement String
    | DownloadReadingsAsCSV
    | CsvData (Result Http.Error String)
    | MessagesResponse (Result Http.Error (List Message))
    | CurrentDate Time.Posix


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
            ( Users.handleResponse result model, getAllMessages MessagesResponse )

        MessagesResponse response ->
            case response of
                Ok messages ->
                    ( { model | messages = Success messages }, getCurrentTime CurrentDate )

                Err err ->
                    ( { model | messages = Failure err }, getCurrentTime CurrentDate )

        CurrentDate timestamp ->
            ( { model | year = toYear utc timestamp, month = timestamp |> toMonth utc |> elmMonthToInt }, Readings.forMonth ReadingResponded (toYear utc timestamp) (timestamp |> toMonth utc |> elmMonthToInt) )

        ReadingResponded result ->
            ( { model | readings = RemoteData.fromResult result }, Cmd.none )

        LoadReadings year month ->
            ( model, Readings.forMonth ReadingResponded year month )

        ChartMsg subMsg ->
            ( { model | chart = Chart.update subMsg model.chart }, Cmd.none )

        SelectChanged selectType value ->
            case selectType of
                Year ->
                    ( { model | year = toInt value 0 }, Readings.forMonth ReadingResponded (toInt value 0) model.month )

                Month ->
                    ( { model | month = monthToInt value }, Readings.forMonth ReadingResponded model.year (monthToInt value) )

        DownloadReadingsAsCSV ->
            ( model, Readings.downloadCsvForMonth CsvData model.year model.month )

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
            , margin auto
            , marginTop (px 50)
            , textAlign center
            ]
        ]
        [ div
            [ css
                [ Css.property "aspect-ratio" "2 / 1"
                ]
            ]
            ([ select [ value (intToMonth (model.month - 1)), onInput (SelectChanged Month) ] (months |> List.map (\m -> option [] [ text m ]))
             , select [ value (model.year |> fromInt), onInput (SelectChanged Year) ]
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
    table []
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
    Html.Styled.map ChartMsg
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
