module Pages.CompareYears exposing (Model, Msg, init, update, view)

import Components.TemperatureProfileChart as Chart
import Components.YearDifferenceChart exposing (colorFor, temperatureBarChart)
import Css exposing (auto, center, displayFlex, flexGrow, flexShrink, int, justifyContent, margin, marginLeft, marginTop, maxHeight, maxWidth, minWidth, pct, px, spaceAround, textAlign, width, zero)
import Css.Global exposing (global, selector)
import Dates exposing (formatRataDie, parseDateToRataDie)
import Dict exposing (Dict)
import Html.Styled exposing (Html, div, fromUnstyled, map, option, select, text)
import Html.Styled.Attributes exposing (class, css, value)
import Html.Styled.Events exposing (onInput)
import Http
import Lib.ElmChart.PieChart exposing (pie)
import List exposing (filter, length, reverse)
import Readings exposing (Reading)
import RemoteData exposing (RemoteData(..), WebData)
import String exposing (fromInt, toInt)
import Users exposing (User)


type alias Model =
    { user : WebData User
    , year1 : ( Int, WebData (List Reading) )
    , year2 : ( Int, WebData (List Reading) )
    , differences : List Reading
    , chart : Chart.Model
    }


init : ( Model, Cmd Msg )
init =
    ( { user = Loading, year1 = ( 2026, NotAsked ), year2 = ( 2026, NotAsked ), chart = Chart.init, differences = [] }
    , Users.info UserResponded
    )


type SelectElement
    = Year1
    | Year2


type Msg
    = UserResponded (Result Http.Error User)
    | ReadingResponded1 (Result Http.Error (List Reading))
    | ReadingResponded2 (Result Http.Error (List Reading))
    | LoadInitial
    | InitialReadingResponse (Result Http.Error (List Reading))
    | ChartMsg Chart.Msg
    | SelectChanged SelectElement String
    | CalculateDifferences


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
            update LoadInitial (Users.handleResponse result model)

        ReadingResponded1 result ->
            update CalculateDifferences { model | year1 = ( Tuple.first model.year1, RemoteData.fromResult result ) }

        ReadingResponded2 result ->
            update CalculateDifferences { model | year2 = ( Tuple.first model.year2, RemoteData.fromResult result ) }

        InitialReadingResponse result ->
            update CalculateDifferences { model | year1 = ( Tuple.first model.year1, RemoteData.fromResult result ), year2 = ( Tuple.first model.year2, RemoteData.fromResult result ) }

        ChartMsg subMsg ->
            ( { model | chart = Chart.update subMsg model.chart }, Cmd.none )

        SelectChanged selectType value ->
            case selectType of
                Year1 ->
                    ( { model | year1 = ( toInt value 0, NotAsked ) }, Readings.forYear ReadingResponded1 (toInt value 0) )

                Year2 ->
                    ( { model | year2 = ( toInt value 0, NotAsked ) }, Readings.forYear ReadingResponded2 (toInt value 0) )

        CalculateDifferences ->
            ( { model | differences = differenceByDay (model.year1 |> Tuple.second |> getList) (model.year2 |> Tuple.second |> getList) }, Cmd.none )

        LoadInitial ->
            ( model, Readings.forYear InitialReadingResponse 2026 )


getList : WebData (List Reading) -> List Reading
getList dat =
    case dat of
        NotAsked ->
            []

        Loading ->
            []

        Failure _ ->
            []

        Success readings ->
            readings


monthDay : String -> String
monthDay date =
    String.dropLeft 5 date


differenceByDay : List Reading -> List Reading -> List Reading
differenceByDay year1 year2 =
    let
        year2Dict : Dict String Reading
        year2Dict =
            Dict.fromList <|
                List.map (\r -> ( monthDay r.date, r )) year2
    in
    List.filterMap
        (\r1 ->
            Dict.get (monthDay r1.date) year2Dict
                |> Maybe.map
                    (\r2 ->
                        { date = r1.date
                        , value = r1.value - r2.value
                        }
                    )
        )
        year1


view : Model -> List (Html Msg)
view model =
    [ div
        [ css
            [ width (pct 90)
            , marginLeft (pct 5)
            , marginTop (px 50)
            , textAlign center
            ]
        ]
        [ select [ value (model.year1 |> Tuple.first |> fromInt), onInput (SelectChanged Year1) ]
            (List.range 2000 2026 |> reverse |> List.map (\e -> option [] [ text (fromInt e) ]))
        , text " vergleichen mit "
        , select [ value (model.year2 |> Tuple.first |> fromInt), onInput (SelectChanged Year2) ]
            (List.range 2000 2026 |> reverse |> List.map (\e -> option [] [ text (fromInt e) ]))
        , div
            [ css
                [ displayFlex
                , justifyContent spaceAround
                ]
            ]
            [ div
                [ css [ flexGrow (int 2), flexShrink (int 1), minWidth zero ] ]
                [ renderChart model.differences model ]
            , div
                [ css [ flexGrow (int 1), flexShrink (int 1), minWidth zero ] ]
                [ renderPieChart model.differences ]
            ]
        ]
    ]


renderChart : List Reading -> Model -> Html Msg
renderChart readings _ =
    let
        points =
            readings
                |> List.filterMap
                    (\reading ->
                        parseDateToRataDie reading.date
                            |> Maybe.map (\rd -> { x = toFloat rd, y = reading.value })
                    )
    in
    map ChartMsg (temperatureBarChart points (\x -> formatRataDie (round x)))


renderPieChart : List Reading -> Html Msg
renderPieChart readings =
    div
        [ class "chart-widget"
        , css [ marginTop (px 50) ]
        ]
        [ global
            [ selector ".chart-widget svg"
                [ maxWidth (pct 100)
                , maxHeight (pct 100)
                , margin auto
                , Css.property "display" "block"
                ]
            ]
        , fromUnstyled
            (pie 300
                [ { color = colorFor 0, value = filter (\v -> v.value == 0) readings |> length |> toFloat }
                , { color = colorFor -1, value = filter (\v -> v.value < 0) readings |> length |> toFloat }
                , { color = colorFor 1, value = filter (\v -> v.value > 0) readings |> length |> toFloat }
                ]
            )
        ]
