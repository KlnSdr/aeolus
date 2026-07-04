module Main exposing (..)

import Browser
import Css exposing (..)
import Html.Styled exposing (Html, div, h1, img, text, toUnstyled)
import Html.Styled.Attributes exposing (alt, css, src)
import Login exposing (doLogin, loginView)
import MainView exposing (doGetUserInfo, getLastReading, mainView)
import NavBar exposing (navBar, unauthNavBar)
import Signup exposing (signupView)
import Types exposing (..)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view >> toUnstyled
        , subscriptions = \_ -> Sub.none
        }


initModel : Model
initModel =
    { page = Landing
    , user = Nothing
    , lastReading = Nothing
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( initModel, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Goto page ->
            case page of
                Main ->
                    ( { model | page = page }, doGetUserInfo )

                _ ->
                    ( { model | page = page }, Cmd.none )

        Action action ->
            case action of
                DoSignIn ->
                    ( model, doLogin "klnsdr" "iamroot" )

                DoSignUp ->
                    update (Goto Main) model

        Response res ->
            case res of
                LoginResponse result ->
                    case result of
                        Ok _ ->
                            update (Goto Main) model

                        Err _ ->
                            ( model, Cmd.none )

                UserResponse result ->
                    case result of
                        Ok user ->
                            ( { model | user = Just user }, getLastReading )

                        Err _ ->
                            ( model, Cmd.none )

                LastReadingResponse result ->
                    case result of
                        Ok lastReading ->
                            ( { model | lastReading = Just lastReading }, Cmd.none )

                        Err _ ->
                            ( model, Cmd.none )


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


mainContent : Model -> List (Html Msg)
mainContent model =
    case model.page of
        Landing ->
            [ unauthNavBar
            , div [ css landingCenterContainer ]
                [ img [ css logoStyle, src "favicon.png", alt "Aeolus" ] []
                , h1 [] [ text "Aeolus" ]
                ]
            ]

        Main ->
            List.concat [ [ navBar model.user ], mainView model ]

        Login ->
            loginView

        Signup ->
            signupView


view : Model -> Html Msg
view model =
    div
        [ css
            [ margin (px 0)
            , padding (px 0)
            , backgroundColor (hex "#f9f9f9")
            , overflowX hidden
            , minHeight (vh 100)
            , fontFamilies [ "Arial", "sans-serif" ]
            ]
        ]
        (mainContent model)
