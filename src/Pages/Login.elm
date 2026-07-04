module Pages.Login exposing (..)

import CommonStyles exposing (buttonStyle)
import Constants exposing (api_url)
import Css exposing (backgroundColor, block, border3, center, display, hex, inlineBlock, left, padding, px, solid, textAlign, textDecoration, underline)
import Html.Styled exposing (Html, a, button, div, h1, input, table, td, text, tr)
import Html.Styled.Attributes exposing (css, type_)
import Html.Styled.Events exposing (onClick)
import Http exposing (header, jsonBody)
import Json.Decode as Decode
import Json.Encode as Encode
import Types exposing (..)


loginView : List (Html Msg)
loginView =
    [ h1 [ css [ textAlign center ] ] [ text "Login" ]
    , div [ css [ textAlign center ] ]
        [ div [ css [ display inlineBlock, textAlign left, padding (px 20), border3 (px 2) solid (hex "#00008b"), backgroundColor (hex "#f9f9f9") ] ]
            [ table []
                [ tr []
                    [ td [] [ text "Username:" ]
                    , td [] [ input [ type_ "text" ] [] ]
                    ]
                , tr []
                    [ td [] [ text "Password:" ]
                    , td [] [ input [ type_ "password" ] [] ]
                    ]
                , tr []
                    [ td [] [ button [ onClick (Action DoSignIn), css buttonStyle ] [ text "Login" ] ]
                    , td [] []
                    ]
                ]
            , a [ onClick (Goto Signup), css [ textDecoration underline, display block, textAlign center ] ] [ text "No account? Signup" ]
            ]
        ]
    ]


doLogin : String -> String -> Cmd Msg
doLogin username password =
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
        , expect = Http.expectJson (Response << LoginResponse) redirectToDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


redirectToDecoder : Decode.Decoder String
redirectToDecoder =
    Decode.field "redirectTo" Decode.string
