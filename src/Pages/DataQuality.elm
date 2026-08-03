module Pages.DataQuality exposing (..)

import CommonStyles exposing (buttonStyle)
import Constants exposing (api_url, token)
import Css exposing (backgroundColor, borderRadius, center, display, height, hex, inlineBlock, left, marginTop, maxWidth, pct, property, px, textAlign, width)
import Html.Styled exposing (Html, button, div, input, label, span, text)
import Html.Styled.Attributes exposing (css, type_, value)
import Html.Styled.Events exposing (onInput)
import Http exposing (header, jsonBody)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import RemoteData exposing (RemoteData(..), WebData)
import String exposing (fromInt, padLeft)
import Users exposing (User)


type alias Model =
    { user : WebData User
    , checkerConfig : WebData CheckerConfig

    -- , popup : Components.Popup.Model Msg
    }


type CheckerStatus
    = Ok
    | Warning
    | Error
    | NoData


type alias CheckerConfig =
    { userId : String
    , enabled : Bool
    , startHour : Int
    , startMinute : Int
    , lastRunDay : Int
    , lastRunMonth : Int
    , lastRunYear : Int
    , lastRunHour : Int
    , lastRunMinute : Int
    , lastRunStatus : CheckerStatus
    }


init : ( Model, Cmd Msg )
init =
    ( { user = Loading, checkerConfig = Loading }
    , Users.info UserResponded
    )


userOf : Model -> Maybe User
userOf model =
    RemoteData.toMaybe model.user


type Msg
    = UserResponded (Result Http.Error User)
    | ConfigResponse (Result Http.Error CheckerConfig)
    | StartTimeChanged String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserResponded result ->
            ( { model | user = RemoteData.fromResult result }
            , case result of
                Result.Ok _ ->
                    getCheckerConfig ConfigResponse

                Err _ ->
                    Cmd.none
            )

        ConfigResponse result ->
            ( { model | checkerConfig = RemoteData.fromResult result }
            , case result of
                Result.Ok _ ->
                    Cmd.none

                Err _ ->
                    Cmd.none
            )

        StartTimeChanged rawValue ->
            case ( model.checkerConfig, parseTime rawValue ) of
                ( Success conf, Just ( hour, minute ) ) ->
                    ( { model | checkerConfig = Success { conf | startHour = hour, startMinute = minute } }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )


view : Model -> List (Html Msg)
view model =
    let
        config =
            case model.checkerConfig of
                Success conf ->
                    conf

                _ ->
                    { userId = ""
                    , enabled = False
                    , startHour = 0
                    , startMinute = 0
                    , lastRunDay = 0
                    , lastRunMonth = 0
                    , lastRunYear = 0
                    , lastRunHour = 0
                    , lastRunMinute = 0
                    , lastRunStatus = NoData
                    }
    in
    [ div [ css [ textAlign center, marginTop (pct 10) ] ]
        [ div []
            [ span
                [ css
                    [ width (px 50)
                    , height (px 50)
                    , borderRadius (pct 50)
                    , display inlineBlock
                    , backgroundColor (config.lastRunStatus |> statusToColor |> hex)
                    ]
                ]
                []
            ]
        , div
            [ css
                [ property "display" "inline-grid"
                , property "grid-template-columns" "repeat(3, 1fr)"
                , property "grid-template-rows" "repeat(4, 1fr)"
                , property "grid-column-gap" "5px"
                , property "grid-row-gap" "5px"
                , maxWidth (px 500)
                , textAlign left
                ]
            ]
            [ label [] [ text "Status:" ]
            , label []
                [ text
                    (if config.enabled then
                        "aktiv"

                     else
                        "inaktiv"
                    )
                ]
            , button [ css buttonStyle ]
                [ text
                    (if config.enabled then
                        "deaktivieren"

                     else
                        "aktivieren"
                    )
                ]
            , label [] [ text "letzte Überprüfung:" ]
            , label []
                [ text
                    (fromInt config.lastRunDay
                        ++ "."
                        ++ fromInt config.lastRunMonth
                        ++ "."
                        ++ fromInt config.lastRunYear
                        ++ " "
                        ++ fromInt config.lastRunHour
                        ++ ":"
                        ++ fromInt config.lastRunMinute
                    )
                ]
            , button [ css buttonStyle ] [ text "manuell überprüfen" ]
            , label [] [ text "Startzeit:" ]
            , input [ type_ "time", value (formatTime config.startHour config.startMinute), onInput StartTimeChanged ] []
            , button [ css buttonStyle ] [ text "speichern" ]
            , div [] []
            , div [] []
            , button [ css buttonStyle ] [ text "Daten interpolieren" ]
            ]
        ]
    ]


formatTime : Int -> Int -> String
formatTime hour minute =
    padLeft 2 '0' (fromInt hour) ++ ":" ++ padLeft 2 '0' (fromInt minute)


parseTime : String -> Maybe ( Int, Int )
parseTime rawValue =
    case String.split ":" rawValue of
        [ hourStr, minuteStr ] ->
            Maybe.map2 Tuple.pair (String.toInt hourStr) (String.toInt minuteStr)

        _ ->
            Nothing


statusToColor : CheckerStatus -> String
statusToColor status =
    case status of
        Ok ->
            "#008000FF"

        Warning ->
            "#FFA500FF"

        Error ->
            "#FF0000FF"

        NoData ->
            "#808080FF"


getCheckerConfig : (Result Http.Error CheckerConfig -> msg) -> Cmd msg
getCheckerConfig toMsg =
    Http.request
        { method = "GET"
        , url = api_url ++ "/rest/data-quality-checker-config"
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectJson toMsg decodeCheckerConfig
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


decodeCheckerConfig : Decoder CheckerConfig
decodeCheckerConfig =
    Decode.succeed CheckerConfig
        |> required "userId" Decode.string
        |> required "enabled" Decode.bool
        |> required "startHour" Decode.int
        |> required "startMinute" Decode.int
        |> required "lastRunDay" Decode.int
        |> required "lastRunMonth" Decode.int
        |> required "lastRunYear" Decode.int
        |> required "lastRunHour" Decode.int
        |> required "lastRunMinute" Decode.int
        |> required "lastRunStatus" decodeCheckerStatus


decodeCheckerStatus : Decoder CheckerStatus
decodeCheckerStatus =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "OK" ->
                        Decode.succeed Ok

                    "WARNING" ->
                        Decode.succeed Warning

                    "ERROR" ->
                        Decode.succeed Error

                    "NO_DATA" ->
                        Decode.succeed NoData

                    _ ->
                        Decode.fail ("Unknown CheckerStatus: " ++ str)
            )
