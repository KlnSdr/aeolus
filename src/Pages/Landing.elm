module Pages.Landing exposing (view)

import Css exposing (..)
import Html.Styled exposing (Html, div, h1, img, text)
import Html.Styled.Attributes exposing (alt, css, src)
import Html.Styled exposing (p)


view : List (Html msg)
view =
    [ div [ css landingCenterContainer ]
        [ img [ css logoStyle, src "favicon.png", alt "Aeolus" ] []
        , h1 [] [ text "Aeolus" ]
        , p [] [text "Bündelt, was sonst verweht"]
        ]
    ]


logoStyle : List Style
logoStyle =
    [ maxWidth (vw 25)
    , maxHeight (vh 25)
    ]


landingCenterContainer : List Style
landingCenterContainer =
    [ marginTop (vh 5)
    , width (vw 50)
    , marginLeft (vw 25)
    , textAlign center
    ]
