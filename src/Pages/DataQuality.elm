module Pages.DataQuality exposing (..)

import CommonStyles exposing (buttonStyle)
import Components.Popup exposing (closed, open)
import Constants exposing (api_url, token)
import Css exposing (backgroundColor, borderRadius, center, display, displayFlex, height, hex, inlineBlock, left, marginTop, maxWidth, pct, property, px, textAlign, width)
import Html.Styled exposing (Html, button, div, h3, input, label, span, text)
import Html.Styled.Attributes exposing (css, type_, value)
import Html.Styled.Events exposing (onClick, onInput)
import Http exposing (header, jsonBody)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import List exposing (map)
import Messages exposing (Message, getAllMessages)
import Readings exposing (Reading)
import RemoteData exposing (RemoteData(..), WebData)
import Round
import String exposing (fromInt, padLeft)
import Users exposing (User)


type alias Model =
    { user : WebData User
    , checkerConfig : WebData CheckerConfig
    , interpolationResult : WebData InterpolationResult
    , popup : Components.Popup.Model Msg
    , messages : WebData (List Message)
    }


type alias InterpolationResult =
    { interpolatedReadings : List Reading
    , notInterpolatedHoles : List String
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


emptyResult : InterpolationResult
emptyResult =
    { interpolatedReadings = []
    , notInterpolatedHoles = []
    }


init : ( Model, Cmd Msg )
init =
    ( { user = Loading
      , checkerConfig = NotAsked
      , interpolationResult = NotAsked
      , popup = closed
      , messages = NotAsked
      }
    , Users.info UserResponded
    )


type Msg
    = UserResponded (Result Http.Error User)
    | ConfigResponse (Result Http.Error CheckerConfig)
    | StartTimeChanged String
    | EnableChecker
    | DisableChecker
    | EnableCheckerResponse (Result Http.Error ())
    | DisableCheckerResponse (Result Http.Error ())
    | RunChecker
    | CheckerRunDoneResponse (Result Http.Error ())
    | UpdateStartTime
    | StartTimeUpdated (Result Http.Error ())
    | RequestInterpolation
    | InterpolationFinished (Result Http.Error InterpolationResult)
    | PopupMsg (Components.Popup.Msg Msg)
    | ShowInterpolationPoup InterpolationResult
    | MessagesResponse (Result Http.Error (List Message))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserResponded result ->
            ( Users.handleResponse result model, getAllMessages MessagesResponse )

        MessagesResponse response ->
            case response of
                Result.Ok messages ->
                    ( { model | messages = Success messages }, getCheckerConfig ConfigResponse )

                Err err ->
                    ( { model | messages = Failure err }, getCheckerConfig ConfigResponse )

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

        EnableChecker ->
            ( { model | checkerConfig = Loading }, enableCheckerForUser EnableCheckerResponse )

        DisableChecker ->
            ( { model | checkerConfig = Loading }, disableCheckerForUser DisableCheckerResponse )

        EnableCheckerResponse _ ->
            ( { model | checkerConfig = Loading }, getCheckerConfig ConfigResponse )

        DisableCheckerResponse _ ->
            ( { model | checkerConfig = Loading }, getCheckerConfig ConfigResponse )

        RunChecker ->
            ( { model | checkerConfig = Loading }, runChecker CheckerRunDoneResponse )

        CheckerRunDoneResponse _ ->
            ( model, getCheckerConfig ConfigResponse )

        UpdateStartTime ->
            case model.checkerConfig of
                Success conf ->
                    ( { model | checkerConfig = Loading }, updateStartTime conf.startHour conf.startMinute StartTimeUpdated )

                _ ->
                    ( model, Cmd.none )

        StartTimeUpdated _ ->
            ( model, getCheckerConfig ConfigResponse )

        RequestInterpolation ->
            ( { model | interpolationResult = Loading }, getInterpolation InterpolationFinished )

        InterpolationFinished result ->
            case result of
                Result.Ok interpolation ->
                    update (ShowInterpolationPoup interpolation) { model | interpolationResult = Success interpolation }

                Err err ->
                    ( { model | interpolationResult = Failure err }, Cmd.none )

        PopupMsg (Components.Popup.ContentMsg subMsg) ->
            update subMsg model

        PopupMsg subMsg ->
            ( { model | popup = Components.Popup.update subMsg model.popup }, Cmd.none )

        ShowInterpolationPoup value ->
            ( { model | popup = value |> interpolationPopup |> open }, Cmd.none )


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

        inProgress =
            case model.checkerConfig of
                Loading ->
                    True

                _ ->
                    False

        interPolationinProgress =
            case model.interpolationResult of
                Loading ->
                    True

                _ ->
                    False
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
                    (if inProgress then
                        "..."

                     else if config.enabled then
                        "aktiv"

                     else
                        "inaktiv"
                    )
                ]
            , button
                (css buttonStyle
                    :: (if not inProgress then
                            [ onClick
                                (if config.enabled then
                                    DisableChecker

                                 else
                                    EnableChecker
                                )
                            ]

                        else
                            []
                       )
                )
                [ text
                    (if inProgress then
                        "..."

                     else if config.enabled then
                        "deaktivieren"

                     else
                        "aktivieren"
                    )
                ]
            , label [] [ text "letzte Überprüfung:" ]
            , label []
                [ text
                    (if inProgress then
                        "..."

                     else
                        (config.lastRunDay |> fromInt |> padLeft 2 '0')
                            ++ "."
                            ++ (config.lastRunMonth |> fromInt |> padLeft 2 '0')
                            ++ "."
                            ++ (config.lastRunYear |> fromInt |> padLeft 2 '0')
                            ++ " "
                            ++ (config.lastRunHour |> fromInt |> padLeft 2 '0')
                            ++ ":"
                            ++ (config.lastRunMinute |> fromInt |> padLeft 2 '0')
                    )
                ]
            , button [ css buttonStyle, onClick RunChecker ]
                [ text
                    (if inProgress then
                        "..."

                     else
                        "manuell überprüfen"
                    )
                ]
            , label [] [ text "Startzeit:" ]
            , input [ type_ "time", value (formatTime config.startHour config.startMinute), onInput StartTimeChanged ] []
            , button
                (css buttonStyle
                    :: (if inProgress then
                            []

                        else
                            [ onClick UpdateStartTime ]
                       )
                )
                [ text
                    (if inProgress then
                        "..."

                     else
                        "speichern"
                    )
                ]
            , div [] []
            , div [] []
            , button
                (css buttonStyle
                    :: (if interPolationinProgress then
                            []

                        else
                            [ onClick RequestInterpolation ]
                       )
                )
                [ text
                    (if interPolationinProgress then
                        "..."

                     else
                        "Daten interpolieren"
                    )
                ]
            ]
        ]
    , Html.Styled.map PopupMsg (Components.Popup.view model.popup)
    ]


interpolationPopup : InterpolationResult -> Html Msg
interpolationPopup interpolationResult =
    div
        [ css
            [ displayFlex
            , property "flex-direction" "column"
            , property "gap" "10px"
            ]
        ]
        (h3 [] [ text "Interpolierte Daten" ]
            :: (interpolationResult.interpolatedReadings
                    |> map
                        (\r ->
                            div
                                [ css
                                    [ displayFlex
                                    , property "flex-direction" "row"
                                    , property "gap" "10px"
                                    ]
                                ]
                                [ span [] [ text r.date ]
                                , span [] [ r.value |> Round.round 2 |> text ]
                                ]
                        )
               )
            ++ h3 [] [ text "Nicht-Interpolierte Daten" ]
            :: (interpolationResult.notInterpolatedHoles
                    |> map
                        (\d ->
                            div []
                                [ text d
                                ]
                        )
               )
        )


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


enableCheckerForUser : (Result Http.Error () -> msg) -> Cmd msg
enableCheckerForUser toMsg =
    Http.request
        { method = "POST"
        , url = api_url ++ "/rest/data-quality-checker-config/enable"
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectWhatever toMsg
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


disableCheckerForUser : (Result Http.Error () -> msg) -> Cmd msg
disableCheckerForUser toMsg =
    Http.request
        { method = "POST"
        , url = api_url ++ "/rest/data-quality-checker-config/disable"
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectWhatever toMsg
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


runChecker : (Result Http.Error () -> msg) -> Cmd msg
runChecker toMsg =
    Http.request
        { method = "POST"
        , url = api_url ++ "/rest/data-quality-checker-config/run"
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectWhatever toMsg
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


updateStartTime : Int -> Int -> (Result Http.Error () -> msg) -> Cmd msg
updateStartTime hour minute toMsg =
    Http.request
        { method = "POST"
        , headers = [ header "Content-Type" "application/json", header "Hades-Login-Token" token ]
        , url = api_url ++ "/rest/data-quality-checker-config/start-time"
        , body =
            jsonBody
                (Encode.object
                    [ ( "hour", Encode.int hour )
                    , ( "minute", Encode.int minute )
                    ]
                )
        , expect = Http.expectWhatever toMsg
        , timeout = Nothing
        , tracker = Nothing
        }


decodeInterpolationResult : Decoder InterpolationResult
decodeInterpolationResult =
    Decode.map2 InterpolationResult
        (Decode.field "interpolatedReadings" (Decode.list Readings.decoder))
        (Decode.field "notInterpolatedHoles" (Decode.list Decode.string))


getInterpolation : (Result Http.Error InterpolationResult -> msg) -> Cmd msg
getInterpolation toMsg =
    Http.request
        { method = "POST"
        , url = api_url ++ "/rest/interpolation"
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectJson toMsg decodeInterpolationResult
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }
