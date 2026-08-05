module Readings exposing (Reading, forMonth, forYear, last, uploadValue, decoder)

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


uploadValue : String -> String -> (Result Http.Error () -> msg) -> Cmd msg
uploadValue date value toMsg =
    request
        { method = "POST"
        , url = api_url ++ "/rest/readings"
        , headers = [ header "Hades-Login-Token" token, header "Content-Type" "application/json" ]
        , body =
            jsonBody
                (Encode.object
                    [ ( "value", Encode.string value )
                    , ( "date", Encode.string date )
                    ]
                )
        , expect = Http.expectStringResponse toMsg addResponseToResult
        , timeout = Nothing
        , tracker = Nothing
        }


addResponseToResult : Http.Response String -> Result Http.Error ()
addResponseToResult response =
    case response of
        Http.BadUrl_ url ->
            Err (Http.BadUrl url)

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError

        Http.BadStatus_ metadata _ ->
            Err (Http.BadStatus metadata.statusCode)

        Http.GoodStatus_ _ _ ->
            Ok ()


listDecoder : Decoder (List Reading)
listDecoder =
    Decode.field "readings" (Decode.list decoder)


decoder : Decoder Reading
decoder =
    Decode.map2 Reading
        (Decode.field "value" Decode.float)
        (Decode.field "date" Decode.string)
