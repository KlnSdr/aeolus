module Users exposing (User, decoder, doLogin, doLogout, doSignup, handleResponse, info, userOf)

import Constants exposing (api_url)
import Http exposing (header, jsonBody, request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import RemoteData exposing (RemoteData(..), WebData)


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
        , headers = []
        , expect = Http.expectJson toMsg decoder
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


userOf : { a | user : WebData User } -> Maybe User
userOf model =
    RemoteData.toMaybe model.user


handleResponse : Result Http.Error User -> { a | user : WebData User } -> { a | user : WebData User }
handleResponse result model =
    { model | user = RemoteData.fromResult result }


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


doSignup : String -> String -> String -> String -> (Result Http.Error () -> msg) -> Cmd msg
doSignup username mail password passwordRepeat toMsg =
    Http.request
        { method = "POST"
        , headers = [ header "Content-Type" "application/json" ]
        , url = api_url ++ "/rest/users"
        , body =
            jsonBody
                (Encode.object
                    [ ( "displayName", Encode.string username )
                    , ( "mail", Encode.string mail )
                    , ( "password", Encode.string password )
                    , ( "passwordRepeat", Encode.string passwordRepeat )
                    ]
                )
        , expect = Http.expectWhatever toMsg
        , timeout = Nothing
        , tracker = Nothing
        }


doLogout : (Result Http.Error () -> msg) -> Cmd msg
doLogout toMsg =
    Http.request
        { method = "GET"
        , headers = []
        , url = api_url ++ "/rest/users/logout"
        , body =
            jsonBody
                (Encode.object
                    []
                )
        , expect = Http.expectWhatever toMsg
        , timeout = Nothing
        , tracker = Nothing
        }


redirectToDecoder : Decode.Decoder String
redirectToDecoder =
    Decode.field "redirectTo" Decode.string
