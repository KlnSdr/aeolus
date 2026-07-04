module Main.Main exposing (..)

import Constants exposing (api_url, token)
import Html.Styled exposing (Html, div, h1, p, text)
import Http exposing (header, jsonBody, request)
import Json.Decode as Decode
import Json.Encode as Encode
import Round
import Types exposing (LastReading, Model, Msg(..), Responses(..), User)


getLastReadingValue : Maybe LastReading -> String
getLastReadingValue lastReading =
    case lastReading of
        Just val ->
            Round.round 1 val.value ++ " °C"

        Nothing ->
            "XY.Z °C"


getLastReadingDate : Maybe LastReading -> String
getLastReadingDate lastReading =
    case lastReading of
        Just val ->
            val.date

        Nothing ->
            "DD.MM.YYYY"


mainView : Model -> List (Html Msg)
mainView model =
    [ div []
        [ h1 [] [ text (getLastReadingValue model.lastReading) ]
        , p [] [ text ("vom: " ++ getLastReadingDate model.lastReading) ]
        ]
    ]


getLastReading : Cmd Msg
getLastReading =
    request
        { method = "GET"
        , url = api_url ++ "/rest/readings/last"
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectJson (Response << LastReadingResponse) lastReadingDecoder
        , body =
            jsonBody
                (Encode.object
                    []
                )
        , timeout = Nothing
        , tracker = Nothing
        }


lastReadingDecoder : Decode.Decoder LastReading
lastReadingDecoder =
    Decode.map2 LastReading
        (Decode.field "value" Decode.float)
        (Decode.field "date" Decode.string)


doGetUserInfo : Cmd Msg
doGetUserInfo =
    request
        { method = "GET"
        , url = api_url ++ "/rest/users/loginuserinfo"
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectJson (Response << UserResponse) userInfoDecoder
        , body =
            jsonBody
                (Encode.object
                    []
                )
        , timeout = Nothing
        , tracker = Nothing
        }


userInfoDecoder : Decode.Decoder User
userInfoDecoder =
    Decode.map3 User
        (Decode.field "mail" Decode.string)
        (Decode.field "displayName" Decode.string)
        (Decode.field "id" Decode.string)
