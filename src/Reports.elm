module Reports exposing (Report, createNewReport, deleteReport, getAllReports)

import Constants exposing (api_url, token)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode


type alias Report =
    { id : String
    , owner : String
    , reportType : String
    , name : String
    , reportFeatures : List String
    , trigger : String
    , scheduleDay : String
    , scheduleHour : Int
    , scheduleMinute : Int
    }


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
        |> required "reportType" Decode.string
        |> required "name" Decode.string
        |> required "reportFeatures" (Decode.list Decode.string)
        |> required "trigger" Decode.string
        |> required "scheduleDay" Decode.string
        |> required "scheduleHour" Decode.int
        |> required "scheduleMinute" Decode.int


encodeReport : Report -> Encode.Value
encodeReport report =
    Encode.object
        [ ( "owner", Encode.string report.owner )
        , ( "reportType", Encode.string report.reportType )
        , ( "name", Encode.string report.name )
        , ( "reportFeatures", Encode.list Encode.string report.reportFeatures )
        , ( "trigger", Encode.string report.trigger )
        , ( "scheduleDay", Encode.string report.scheduleDay )
        , ( "scheduleHour", Encode.int report.scheduleHour )
        , ( "scheduleMinute", Encode.int report.scheduleMinute )
        ]
