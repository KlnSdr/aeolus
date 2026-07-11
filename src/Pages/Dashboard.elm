module Pages.Dashboard exposing (Model, Msg, init, update, userOf, view)

import Css exposing (Style, bolder, center, em, fontSize, fontWeight, margin, marginTop, pct, px, textAlign)
import Html.Styled exposing (Html, div, h1, p, text)
import Html.Styled.Attributes exposing (css)
import Http
import Readings exposing (Reading)
import RemoteData exposing (RemoteData(..), WebData)
import Round
import Users exposing (User)


type alias Model =
    { user : WebData User
    , lastReading : WebData Reading
    }


init : ( Model, Cmd Msg )
init =
    ( { user = Loading, lastReading = NotAsked }
    , Users.info UserResponded
    )


userOf : Model -> Maybe User
userOf model =
    RemoteData.toMaybe model.user


type Msg
    = UserResponded (Result Http.Error User)
    | LastReadingResponded (Result Http.Error Reading)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserResponded result ->
            ( { model | user = RemoteData.fromResult result }
            , case result of
                Ok _ ->
                    Readings.last LastReadingResponded

                Err _ ->
                    Cmd.none
            )

        LastReadingResponded result ->
            ( { model | lastReading = RemoteData.fromResult result }, Cmd.none )


view : Model -> List (Html Msg)
view model =
    [ div [ css [ textAlign center, marginTop (pct 10) ] ] (viewLastReading model.lastReading) ]


huge : List Style
huge =
    [ fontSize (em 5)
    , fontWeight bolder
    , margin (px 0)
    ]


viewLastReading : WebData Reading -> List (Html msg)
viewLastReading remoteReading =
    case remoteReading of
        NotAsked ->
            [ h1 [ css huge ] [ text "XY.Z °C" ], p [] [ text "vom: DD.MM.YYYY" ] ]

        Loading ->
            [ h1 [ css huge ] [ text "Loading..." ] ]

        Failure _ ->
            [ h1 [ css huge ] [ text "Couldn't load the last reading." ] ]

        Success reading ->
            [ h1 [ css huge ] [ text (Round.round 1 reading.value ++ " °C") ]
            , p [] [ text ("vom: " ++ reading.date) ]
            ]
