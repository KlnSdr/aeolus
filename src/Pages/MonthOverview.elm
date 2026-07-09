module Pages.MonthOverview exposing (Model, Msg, init, update, userOf, view)

import Components.TemperatureProfileChart as Chart
import Constants exposing (intToMonth, monthToInt, months)
import Css exposing (center, marginLeft, marginTop, pct, px, textAlign, width)
import Dates exposing (formatRataDie, parseDateToRataDie)
import Html.Styled exposing (Html, div, map, option, p, select, text)
import Html.Styled.Attributes exposing (css, value)
import Html.Styled.Events exposing (onInput)
import Http
import List exposing (reverse)
import Readings exposing (Reading)
import RemoteData exposing (RemoteData(..), WebData)
import Round
import String exposing (fromInt, toInt)
import Users exposing (User)


type alias Model =
    { user : WebData User
    , readings : WebData (List Reading)
    , chart : Chart.Model
    , year : Int
    , month : Int
    }


init : ( Model, Cmd Msg )
init =
    ( { user = Loading, readings = NotAsked, chart = Chart.init, year = 2026, month = 1 }
    , Users.info UserResponded
    )


userOf : Model -> Maybe User
userOf model =
    RemoteData.toMaybe model.user


type SelectElement
    = Year
    | Month


type Msg
    = UserResponded (Result Http.Error User)
    | ReadingResponded (Result Http.Error (List Reading))
    | ChartMsg Chart.Msg
    | LoadReadings Int Int
    | SelectChanged SelectElement String


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
            ( { model | user = RemoteData.fromResult result }
            , case result of
                Ok _ ->
                    Readings.forMonth ReadingResponded model.year model.month

                Err _ ->
                    Cmd.none
            )

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


view : Model -> List (Html Msg)
view model =
    [ div
        [ css
            [ width (pct 50)
            , Css.property "aspect-ratio" "2 / 1"
            , marginLeft (pct 25)
            , marginTop (px 50)
            , textAlign center
            ]
        ]
        [ select [ value (intToMonth (model.month - 1)), onInput (SelectChanged Month) ] (months |> List.map (\m -> option [] [ text m ]))
        , select [ value (model.year |> fromInt), onInput (SelectChanged Year) ]
            (List.range 2000 2026 |> reverse |> List.map (\e -> option [] [ text (fromInt e) ]))
        , case model.readings of
            NotAsked ->
                p [] [ text "Loading..." ]

            Loading ->
                p [] [ text "Loading..." ]

            Failure _ ->
                p [] [ text "Couldn't load readings." ]

            Success readings ->
                renderChart readings model
        ]
    ]


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
