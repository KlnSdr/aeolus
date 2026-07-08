module Pages.YearOverview exposing (Model, Msg, init, update, userOf, view)

import Components.TemperatureProfileChart as Chart
import Constants exposing (api_url, token)
import Css exposing (center, marginLeft, marginTop, pct, px, textAlign, width)
import Html.Styled exposing (Html, div, map, option, p, select, text)
import Html.Styled.Attributes exposing (css, value)
import Html.Styled.Events exposing (onInput)
import Http exposing (header, jsonBody, request)
import Json.Decode as Decode
import Json.Encode as Encode
import List exposing (reverse)
import RemoteData exposing (RemoteData(..), WebData)
import Round
import String exposing (fromInt, toInt)
import Types exposing (Reading, User)


type alias Model =
    { user : WebData User
    , readings : WebData (List Reading)
    , chart : Chart.Model
    , year : Int
    }


init : ( Model, Cmd Msg )
init =
    ( { user = Loading, readings = NotAsked, chart = Chart.init, year = 2026 }
    , doGetUserInfo
    )


userOf : Model -> Maybe User
userOf model =
    RemoteData.toMaybe model.user


type SelectElement
    = Year


type Msg
    = UserResponded (Result Http.Error User)
    | ReadingResponded (Result Http.Error (List Reading))
    | ChartMsg Chart.Msg
    | LoadReadings Int
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
                    loadReadingsForYear model.year

                Err _ ->
                    Cmd.none
            )

        ReadingResponded result ->
            ( { model | readings = RemoteData.fromResult result }, Cmd.none )

        LoadReadings year ->
            ( model, loadReadingsForYear year )

        ChartMsg subMsg ->
            ( { model | chart = Chart.update subMsg model.chart }, Cmd.none )

        SelectChanged selectType value ->
            case selectType of
                Year ->
                    ( { model | year = toInt value 0 }, loadReadingsForYear (toInt value 0) )


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
        [ select [ value (model.year |> fromInt), onInput (SelectChanged Year) ]
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


doGetUserInfo : Cmd Msg
doGetUserInfo =
    request
        { method = "GET"
        , url = api_url ++ "/rest/users/loginuserinfo"
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectJson UserResponded userInfoDecoder
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


userInfoDecoder : Decode.Decoder User
userInfoDecoder =
    Decode.map3 User
        (Decode.field "mail" Decode.string)
        (Decode.field "displayName" Decode.string)
        (Decode.field "id" Decode.string)


loadReadingsForYear : Int -> Cmd Msg
loadReadingsForYear year =
    request
        { method = "GET"
        , url = api_url ++ "/rest/readings/" ++ fromInt year
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectJson ReadingResponded readingsDecoder
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


readingsDecoder : Decode.Decoder (List Reading)
readingsDecoder =
    Decode.field "readings" (Decode.list readingDecoder)


readingDecoder : Decode.Decoder Reading
readingDecoder =
    Decode.map2 Reading
        (Decode.field "value" Decode.float)
        (Decode.field "date" Decode.string)


parseDateToRataDie : String -> Maybe Int
parseDateToRataDie dateString =
    case String.split "-" dateString of
        [ yStr, mStr, dStr ] ->
            Maybe.map3 toRataDie
                (String.toInt yStr)
                (String.toInt mStr)
                (String.toInt dStr)

        _ ->
            Nothing


formatRataDie : Int -> String
formatRataDie n =
    let
        { day, month } =
            fromRataDie n

        pad x =
            String.padLeft 2 '0' (fromInt x)
    in
    pad day ++ "." ++ pad month


toRataDie : Int -> Int -> Int -> Int
toRataDie year month day =
    let
        y =
            if month <= 2 then
                year - 1

            else
                year

        era =
            (if y >= 0 then
                y

             else
                y - 399
            )
                // 400

        yoe =
            y - era * 400

        mp =
            modBy 12 (month + 9)

        doy =
            (153 * mp + 2) // 5 + day - 1

        doe =
            yoe * 365 + yoe // 4 - yoe // 100 + doy
    in
    era * 146097 + doe - 719468


fromRataDie : Int -> { year : Int, month : Int, day : Int }
fromRataDie z0 =
    let
        z =
            z0 + 719468

        era =
            (if z >= 0 then
                z

             else
                z - 146096
            )
                // 146097

        doe =
            z - era * 146097

        yoe =
            (doe - doe // 1460 + doe // 36524 - doe // 146096) // 365

        y =
            yoe + era * 400

        doy =
            doe - (365 * yoe + yoe // 4 - yoe // 100)

        mp =
            (5 * doy + 2) // 153

        day =
            doy - (153 * mp + 2) // 5 + 1

        month =
            if mp < 10 then
                mp + 3

            else
                mp - 9
    in
    { year =
        if month <= 2 then
            y + 1

        else
            y
    , month = month
    , day = day
    }
