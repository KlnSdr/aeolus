module Users exposing (User, doLogin, info)

import Constants exposing (api_url, token)
import Http exposing (header, jsonBody, request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias User =
    { mail : String
    , displayName : String
    , id : String
    }


info : (Result Http.Error User -> msg) -> Cmd msg
info toMsg =
    request
        { method = "GET"
        , url = api_url ++ "/rest/users/loginuserinfo"
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectJson toMsg decoder
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


decoder : Decoder User
decoder =
    Decode.map3 User
        (Decode.field "mail" Decode.string)
        (Decode.field "displayName" Decode.string)
        (Decode.field "id" Decode.string)


doLogin : String -> String -> (Result Http.Error String -> msg) -> Cmd msg
doLogin username password toMsg =
    Http.request
        { method = "POST"
        , headers = [ header "Content-Type" "application/json" ]
        , url = api_url ++ "/rest/users/login"
        , body =
            jsonBody
                (Encode.object
                    [ ( "displayName", Encode.string username )
                    , ( "password", Encode.string password )
                    ]
                )
        , expect = Http.expectJson toMsg redirectToDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


redirectToDecoder : Decode.Decoder String
redirectToDecoder =
    Decode.field "redirectTo" Decode.string
