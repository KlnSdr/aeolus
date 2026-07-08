module Pages.MonthOverview exposing (Model, Msg, init, update, userOf, view)

import Chart as C
import Chart.Attributes as CA
import Chart.Events as CE
import Chart.Item as CI
import Constants exposing (api_url, token)
import Css exposing (marginLeft, marginTop, maxHeight, maxWidth, pct, property, px, width)
import Css.Global exposing (global, selector)
import Html
import Html.Styled exposing (Html, div, fromUnstyled, p, text)
import Html.Styled.Attributes exposing (class, css)
import Http exposing (header, jsonBody, request)
import Json.Decode as Decode
import Json.Encode as Encode
import RemoteData exposing (RemoteData(..), WebData)
import Round
import String exposing (fromInt)
import Types exposing (Reading, User)


type alias Model =
    { user : WebData User
    , readings : WebData (List Reading)
    , hovering : List (CI.One { x : Float, y : Float } CI.Dot)
    }


init : ( Model, Cmd Msg )
init =
    ( { user = Loading, readings = NotAsked, hovering = [] }
    , doGetUserInfo
    )


userOf : Model -> Maybe User
userOf model =
    RemoteData.toMaybe model.user


type Msg
    = UserResponded (Result Http.Error User)
    | ReadingResponded (Result Http.Error (List Reading))
    | OnHover (List (CI.One { x : Float, y : Float } CI.Dot))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserResponded result ->
            ( { model | user = RemoteData.fromResult result }
            , case result of
                Ok _ ->
                    loadReadingsForMonth

                Err _ ->
                    Cmd.none
            )

        ReadingResponded result ->
            ( { model | readings = RemoteData.fromResult result }, Cmd.none )

        OnHover hovering ->
            ( { model | hovering = hovering }, Cmd.none )


view : Model -> List (Html Msg)
view model =
    case model.readings of
        NotAsked ->
            [ p [] [ text "X" ] ]

        Loading ->
            [ p [] [ text "Loading..." ] ]

        Failure _ ->
            [ p [] [ text "Couldn't load readings." ] ]

        Success readings ->
            [ renderChart readings model ]


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
    div
        [ class "month-chart"
        , css
            [ width (pct 50)
            , maxHeight (pct 25)
            , property "aspect-ratio" "2 / 1"
            , marginLeft (pct 25)
            , marginTop (px 50)
            ]
        ]
        [ global
            [ selector ".month-chart svg"
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
                [ C.xAxis []
                , C.xLabels
                    [ CA.amount 8
                    , CA.format (\x -> formatRataDie (round x))
                    ]
                , C.yAxis []
                , C.yLabels [ CA.withGrid ]
                , C.series .x
                    [ C.interpolated .y [ CA.monotone, CA.color "#00008b" ] [ CA.circle ]
                    ]
                    points
                , C.each model.hovering <|
                    \_ item ->
                        [ C.tooltip item [] [] [ Html.text (Round.round 1 (CI.getY item) ++ " °C") ] ]
                ]
            )
        ]


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


loadReadingsForMonth : Cmd Msg
loadReadingsForMonth =
    request
        { method = "GET"
        , url = api_url ++ "/rest/readings/2026/2"
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

        year =
            if month <= 2 then
                y + 1

            else
                y
    in
    { year = year, month = month, day = day }
