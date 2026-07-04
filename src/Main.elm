module Main exposing (..)

import Browser
import Css exposing (..)
import Html.Styled exposing (Html, div, h1, img, text, toUnstyled)
import Html.Styled.Attributes exposing (alt, css, src)
import Http exposing (header, jsonBody, request)
import Json.Decode as Decode
import Json.Encode as Encode
import Login exposing (loginView)
import MainView exposing (mainView)
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
                        Ok target ->
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


api_url : String
api_url =
    "http://localhost:3000/http://localhost:3333"


token : String
token =
    "..."


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
