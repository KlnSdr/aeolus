module CommonStyles exposing (buttonStyle)

import Css exposing (..)


buttonStyle : List Style
buttonStyle =
    [ border3 (px 2) solid (hex "#00008b")
    , backgroundColor (hex "#00008b")
    , color (hex "#f9f9f9")
    , hover
        [ backgroundColor (hex "#f9f9f9")
        , color (hex "#00008b")
        ]
    ]
