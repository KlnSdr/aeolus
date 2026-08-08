module Reports exposing (Report, ReportFeature(..), ReportSchedule(..), ReportTrigger(..), ReportType(..), createNewReport, deleteReport, getAllReports, render, reportFeatureToDisplayString, reportScheduleToDisplayString, reportTriggerToDisplayString, reportTypeToDisplayString)

import Constants exposing (api_url, token)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import List exposing (map)
import Ports exposing (openInNewTab)


type alias Report =
    { id : String
    , owner : String
    , reportType : ReportType
    , name : String
    , reportFeatures : List ReportFeature
    , trigger : ReportTrigger
    , scheduleDay : ReportSchedule
    , scheduleHour : Int
    , scheduleMinute : Int
    }


type ReportType
    = Monthly
    | Yearly


reportTypeToString : ReportType -> String
reportTypeToString reportType =
    case reportType of
        Monthly ->
            "MONTH"

        Yearly ->
            "YEAR"


reportTypeToDisplayString : ReportType -> String
reportTypeToDisplayString reportType =
    case reportType of
        Monthly ->
            "Monatsbericht"

        Yearly ->
            "Jahresbericht"


type ReportSchedule
    = Unset
    | FirstDayOfMonth
    | FirstDayOfWeek
    | FirstDayOfYear


reportScheduleToString : ReportSchedule -> String
reportScheduleToString reportSchedule =
    case reportSchedule of
        Unset ->
            "UNSET"

        FirstDayOfMonth ->
            "FIRST_DAY_OF_MONTH"

        FirstDayOfWeek ->
            "FIRST_DAY_OF_WEEK"

        FirstDayOfYear ->
            "FIRST_DAY_OF_YEAR"


reportScheduleToDisplayString : ReportSchedule -> String
reportScheduleToDisplayString reportSchedule =
    case reportSchedule of
        Unset ->
            "nicht festgelegt"

        FirstDayOfMonth ->
            "erster Tag des Monats"

        FirstDayOfWeek ->
            "erster Tag der Woche"

        FirstDayOfYear ->
            "erster Tag des Jahres"


type ReportFeature
    = TemperatureCurve
    | Trend
    | Averages
    | OperatingHoursHeatingCurve
    | OperatingHoursWaterCurve
    | OperatingHoursTwoCurve
    | HighTariffPowerCurve
    | LowTariffPowerCurve
    | HouseholdPowerCurve
    | HouseholdWaterCurve


reportFeatureToString : ReportFeature -> String
reportFeatureToString reportFeature =
    case reportFeature of
        TemperatureCurve ->
            "TEMPERATURE_CURVE"

        Trend ->
            "TREND"

        Averages ->
            "AVERAGES"

        OperatingHoursHeatingCurve ->
            "OPERATING_HOURS_HEATING_CURVE"

        OperatingHoursWaterCurve ->
            "OPERATING_HOURS_WATER_CURVE"

        OperatingHoursTwoCurve ->
            "OPERATING_HOURS_TWO_CURVE"

        HighTariffPowerCurve ->
            "HIGH_TARIFF_POWER_CURVE"

        LowTariffPowerCurve ->
            "LOW_TARIFF_POWER_CURVE"

        HouseholdPowerCurve ->
            "HOUSEHOLD_POWER_CURVE"

        HouseholdWaterCurve ->
            "HOUSEHOLD_WATER_CURVE"


reportFeatureToDisplayString : ReportFeature -> String
reportFeatureToDisplayString reportFeature =
    case reportFeature of
        TemperatureCurve ->
            "Temperaturverlauf"

        Trend ->
            "Trends"

        Averages ->
            "Durchschnittswerte"

        OperatingHoursHeatingCurve ->
            "Verlauf Betriebsstunden Heizung"

        OperatingHoursWaterCurve ->
            "Verlauf Betriebsstunden Wasser"

        OperatingHoursTwoCurve ->
            "Verlauf Betriebsstunden 2"

        HighTariffPowerCurve ->
            "Verlauf Stromverbrauch Hochtarif"

        LowTariffPowerCurve ->
            "Verlauf Stromverbrauch Niedertarif"

        HouseholdPowerCurve ->
            "Verlauf Stromverbrauch"

        HouseholdWaterCurve ->
            "Verlauf Wasserverbrauch"


type ReportTrigger
    = Manual
    | Schedule


reportTriggerToString : ReportTrigger -> String
reportTriggerToString reportTrigger =
    case reportTrigger of
        Manual ->
            "MANUAL"

        Schedule ->
            "SCHEDULED"


reportTriggerToDisplayString : ReportTrigger -> String
reportTriggerToDisplayString reportTrigger =
    case reportTrigger of
        Manual ->
            "manuell"

        Schedule ->
            "automatisch"


getAllReports : (Result Http.Error (List Report) -> msg) -> Cmd msg
getAllReports toMsg =
    Http.request
        { method = "GET"
        , url = api_url ++ "/rest/report"
        , headers = [ Http.header "Hades-Login-Token" token ]
        , expect = Http.expectJson toMsg (Decode.field "reports" (Decode.list decodeReport))
        , body = Http.jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


deleteReport : (Result Http.Error () -> msg) -> String -> Cmd msg
deleteReport toMsg id =
    Http.request
        { method = "DELETE"
        , url = api_url ++ "/rest/report/id/" ++ id
        , headers = [ Http.header "Hades-Login-Token" token ]
        , expect = Http.expectWhatever toMsg
        , body = Http.jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


createNewReport : (Result Http.Error Report -> msg) -> Report -> Cmd msg
createNewReport toMsg report =
    Http.request
        { method = "POST"
        , url = api_url ++ "/rest/report"
        , headers = [ Http.header "Hades-Login-Token" token ]
        , expect = Http.expectJson toMsg decodeReport
        , body = Http.jsonBody <| encodeReport <| report
        , timeout = Nothing
        , tracker = Nothing
        }


decodeReport : Decoder Report
decodeReport =
    Decode.succeed Report
        |> required "id" Decode.string
        |> required "owner" Decode.string
        |> required "reportType" decodeReportType
        |> required "name" Decode.string
        |> required "reportFeatures" (Decode.list decodeReportFeature)
        |> required "trigger" decodeReportTrigger
        |> required "scheduleDay" decodeReportSchedule
        |> required "scheduleHour" Decode.int
        |> required "scheduleMinute" Decode.int


encodeReport : Report -> Encode.Value
encodeReport report =
    Encode.object
        [ ( "owner", Encode.string report.owner )
        , ( "reportType", Encode.string <| reportTypeToString <| report.reportType )
        , ( "name", Encode.string report.name )
        , ( "reportFeatures", Encode.list Encode.string <| map reportFeatureToString <| report.reportFeatures )
        , ( "trigger", Encode.string <| reportTriggerToString <| report.trigger )
        , ( "scheduleDay", Encode.string <| reportScheduleToString <| report.scheduleDay )
        , ( "scheduleHour", Encode.int report.scheduleHour )
        , ( "scheduleMinute", Encode.int report.scheduleMinute )
        ]


decodeReportType : Decoder ReportType
decodeReportType =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "YEAR" ->
                        Decode.succeed Yearly

                    "MONTH" ->
                        Decode.succeed Monthly

                    _ ->
                        Decode.fail ("Unknown ReportType: " ++ str)
            )


decodeReportFeature : Decoder ReportFeature
decodeReportFeature =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "TEMPERATURE_CURVE" ->
                        Decode.succeed TemperatureCurve

                    "TREND" ->
                        Decode.succeed Trend

                    "AVERAGES" ->
                        Decode.succeed Averages

                    "OPERATING_HOURS_HEATING_CURVE" ->
                        Decode.succeed OperatingHoursHeatingCurve

                    "OPERATING_HOURS_WATER_CURVE" ->
                        Decode.succeed OperatingHoursWaterCurve

                    "OPERATING_HOURS_TWO_CURVE" ->
                        Decode.succeed OperatingHoursTwoCurve

                    "HIGH_TARIFF_POWER_CURVE" ->
                        Decode.succeed HighTariffPowerCurve

                    "LOW_TARIFF_POWER_CURVE" ->
                        Decode.succeed LowTariffPowerCurve

                    "HOUSEHOLD_POWER_CURVE" ->
                        Decode.succeed HouseholdPowerCurve

                    "HOUSEHOLD_WATER_CURVE" ->
                        Decode.succeed HouseholdWaterCurve

                    _ ->
                        Decode.fail ("Unknown ReportFeature: " ++ str)
            )


decodeReportSchedule : Decoder ReportSchedule
decodeReportSchedule =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "UNSET" ->
                        Decode.succeed Unset

                    "FIRST_DAY_OF_MONTH" ->
                        Decode.succeed FirstDayOfMonth

                    "FIRST_DAY_OF_WEEK" ->
                        Decode.succeed FirstDayOfWeek

                    "FIRST_DAY_OF_YEAR" ->
                        Decode.succeed FirstDayOfYear

                    _ ->
                        Decode.fail ("Unknown ReportSchedule: " ++ str)
            )


decodeReportTrigger : Decoder ReportTrigger
decodeReportTrigger =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "MANUAL" ->
                        Decode.succeed Manual

                    "SCHEDULED" ->
                        Decode.succeed Schedule

                    _ ->
                        Decode.fail ("Unknown ReportTrigger: " ++ str)
            )


render : Report -> Cmd none
render report =
    openInNewTab <| api_url ++ "/rest/report/id/" ++ report.id ++ "/render"
