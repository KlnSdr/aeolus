module Readings exposing (Reading, forMonth, forYear, last)

import Constants exposing (api_url, token)
import Http exposing (header, jsonBody, request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import String exposing (fromInt)


type alias Reading =
    { value : Float
    , date : String
    }


forYear : (Result Http.Error (List Reading) -> msg) -> Int -> Cmd msg
forYear toMsg year =
    request
        { method = "GET"
        , url = api_url ++ "/rest/readings/" ++ fromInt year
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectJson toMsg listDecoder
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


forMonth : (Result Http.Error (List Reading) -> msg) -> Int -> Int -> Cmd msg
forMonth toMsg year month =
    request
        { method = "GET"
        , url = api_url ++ "/rest/readings/" ++ fromInt year ++ "/" ++ fromInt month
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectJson toMsg listDecoder
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


last : (Result Http.Error Reading -> msg) -> Cmd msg
last toMsg =
    request
        { method = "GET"
        , url = api_url ++ "/rest/readings/last"
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectJson toMsg decoder
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


listDecoder : Decoder (List Reading)
listDecoder =
    Decode.field "readings" (Decode.list decoder)


decoder : Decoder Reading
decoder =
    Decode.map2 Reading
        (Decode.field "value" Decode.float)
        (Decode.field "date" Decode.string)
