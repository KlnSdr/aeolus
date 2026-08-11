module ReportsTests exposing (suite)

import Expect
import Json.Decode as Decode
import Reports
    exposing
        ( ReportFeature(..)
        , ReportSchedule(..)
        , ReportTrigger(..)
        , ReportType(..)
        , allReportFeatures
        , allReportSchedules
        , allReportTrigger
        , allReportTypes
        , reportFeatureToDisplayString
        , reportScheduleToDisplayString
        , reportTriggerToDisplayString
        , reportTypeToDisplayString
        )
import Test exposing (Test, describe, test)


reportJson : String
reportJson =
    """
    { "id": "abc123"
    , "owner": "alice"
    , "reportType": "MONTH"
    , "name": "Monthly heating report"
    , "reportFeatures": ["TEMPERATURE_CURVE", "AVERAGES"]
    , "trigger": "SCHEDULED"
    , "scheduleDay": "FIRST_DAY_OF_MONTH"
    , "scheduleHour": 6
    , "scheduleMinute": 30
    }
    """


decodeTests : Test
decodeTests =
    describe "decoding a report"
        [ test "decodes all fields correctly" <|
            \_ ->
                reportJson
                    |> Decode.decodeString Reports.decodeReport
                    |> Expect.equal
                        (Ok
                            { id = "abc123"
                            , owner = "alice"
                            , reportType = Monthly
                            , name = "Monthly heating report"
                            , reportFeatures = [ TemperatureCurve, Averages ]
                            , trigger = Schedule
                            , scheduleDay = FirstDayOfMonth
                            , scheduleHour = 6
                            , scheduleMinute = 30
                            }
                        )
        , test "fails on an unknown reportType" <|
            \_ ->
                """{"id":"1","owner":"a","reportType":"WEEK","name":"n","reportFeatures":[],"trigger":"MANUAL","scheduleDay":"UNSET","scheduleHour":0,"scheduleMinute":0}"""
                    |> Decode.decodeString Reports.decodeReport
                    |> Expect.err
        , test "fails on an unknown reportFeature" <|
            \_ ->
                """{"id":"1","owner":"a","reportType":"MONTH","name":"n","reportFeatures":["NOT_A_FEATURE"],"trigger":"MANUAL","scheduleDay":"UNSET","scheduleHour":0,"scheduleMinute":0}"""
                    |> Decode.decodeString Reports.decodeReport
                    |> Expect.err
        ]


encodeReportTests : Test
encodeReportTests =
    describe "encodeReport"
        [ test "produces the create-report payload shape, without id/owner" <|
            \_ ->
                let
                    report =
                        { id = "xyz"
                        , owner = "bob"
                        , reportType = Yearly
                        , name = "Yearly report"
                        , reportFeatures = [ Trend ]
                        , trigger = Schedule
                        , scheduleDay = FirstDayOfWeek
                        , scheduleHour = 6
                        , scheduleMinute = 5
                        }

                    fieldsDecoder =
                        Decode.map6
                            (\a b c d e f ->
                                { reportType = a
                                , name = b
                                , reportFeatures = c
                                , trigger = d
                                , scheduleDay = e
                                , scheduleTime = f
                                }
                            )
                            (Decode.field "reportType" Decode.string)
                            (Decode.field "name" Decode.string)
                            (Decode.field "reportFeatures" (Decode.list Decode.string))
                            (Decode.field "trigger" Decode.string)
                            (Decode.field "scheduleDay" Decode.string)
                            (Decode.field "scheduleTime" Decode.string)
                in
                report
                    |> Reports.encodeReport
                    |> Decode.decodeValue fieldsDecoder
                    |> Expect.equal
                        (Ok
                            { reportType = "YEAR"
                            , name = "Yearly report"
                            , reportFeatures = [ "TREND" ]
                            , trigger = "SCHEDULED"
                            , scheduleDay = "FIRST_DAY_OF_WEEK"
                            , scheduleTime = "6:05"
                            }
                        )
        , test "does not include id or owner" <|
            \_ ->
                let
                    report =
                        { id = "xyz"
                        , owner = "bob"
                        , reportType = Monthly
                        , name = "n"
                        , reportFeatures = []
                        , trigger = Manual
                        , scheduleDay = Unset
                        , scheduleHour = 0
                        , scheduleMinute = 0
                        }
                in
                report
                    |> Reports.encodeReport
                    |> Decode.decodeValue (Decode.field "id" Decode.string)
                    |> Expect.err
        ]


displayStringsAreExhaustiveAndNonEmpty : Test
displayStringsAreExhaustiveAndNonEmpty =
    describe "display strings"
        [ test "every report type has a non-empty display string" <|
            \_ ->
                allReportTypes
                    |> List.map reportTypeToDisplayString
                    |> List.all (\s -> String.length s > 0)
                    |> Expect.equal True
        , test "every report feature has a non-empty display string" <|
            \_ ->
                allReportFeatures
                    |> List.map reportFeatureToDisplayString
                    |> List.all (\s -> String.length s > 0)
                    |> Expect.equal True
        , test "every report trigger has a non-empty display string" <|
            \_ ->
                allReportTrigger
                    |> List.map reportTriggerToDisplayString
                    |> List.all (\s -> String.length s > 0)
                    |> Expect.equal True
        , test "every report schedule has a non-empty display string" <|
            \_ ->
                allReportSchedules
                    |> List.map reportScheduleToDisplayString
                    |> List.all (\s -> String.length s > 0)
                    |> Expect.equal True
        ]


suite : Test
suite =
    describe "Reports"
        [ decodeTests
        , encodeReportTests
        , displayStringsAreExhaustiveAndNonEmpty
        ]
