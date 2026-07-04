module Pages.Signup exposing (..)

import CommonStyles exposing (buttonStyle)
import Css exposing (backgroundColor, block, border3, center, display, hex, inlineBlock, left, padding, px, solid, textAlign, textDecoration, underline)
import Html.Styled exposing (Html, a, button, div, h1, input, table, td, text, tr)
import Html.Styled.Attributes exposing (css, type_)
import Html.Styled.Events exposing (onClick)
import Types exposing (..)


signupView : List (Html Msg)
signupView =
    [ h1 [ css [ textAlign center ] ] [ text "Signup" ]
    , div [ css [ textAlign center ] ]
        [ div [ css [ display inlineBlock, textAlign left, padding (px 20), border3 (px 2) solid (hex "#00008b"), backgroundColor (hex "#f9f9f9") ] ]
            [ table []
                [ tr []
                    [ td [] [ text "Username:" ]
                    , td [] [ input [ type_ "text" ] [] ]
                    ]
                , tr []
                    [ td [] [ text "E-Mail:" ]
                    , td [] [ input [ type_ "text" ] [] ]
                    ]
                , tr []
                    [ td [] [ text "Password:" ]
                    , td [] [ input [ type_ "password" ] [] ]
                    ]
                , tr []
                    [ td [] [ text "Repeat password:" ]
                    , td [] [ input [ type_ "password" ] [] ]
                    ]
                , tr []
                    [ td [] [ button [ onClick (Action DoSignUp), css buttonStyle ] [ text "Signup" ] ]
                    , td [] []
                    ]
                ]
            , a [ onClick (Goto Login), css [ textDecoration underline, display block, textAlign center ] ] [ text "Already have an account? Login" ]
            ]
        ]
    ]
