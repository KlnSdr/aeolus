module Pages.Login exposing (Model, Msg(..), OutMsg(..), init, update, view)

import CommonStyles exposing (buttonStyle)
import Css exposing (backgroundColor, block, border3, center, color, display, hex, inlineBlock, left, padding, px, solid, textAlign, textDecoration, underline)
import Html.Styled exposing (Html, a, button, div, h1, input, table, td, text, tr)
import Html.Styled.Attributes exposing (css, type_, value)
import Html.Styled.Events exposing (onClick, onInput)
import Http
import Users


type alias Model =
    { username : String
    , password : String
    , error : Maybe String
    }


init : Model
init =
    { username = "", password = "", error = Nothing }


type Msg
    = UsernameChanged String
    | PasswordChanged String
    | SubmitClicked
    | GotoSignupClicked
    | LoginResponded (Result Http.Error String)


type OutMsg
    = NoOp
    | RequestSignup
    | LoggedInAs


update : Msg -> Model -> ( Model, Cmd Msg, OutMsg )
update msg model =
    case msg of
        UsernameChanged v ->
            ( { model | username = v }, Cmd.none, NoOp )

        PasswordChanged v ->
            ( { model | password = v }, Cmd.none, NoOp )

        SubmitClicked ->
            ( { model | error = Nothing }, Users.doLogin model.username model.password LoginResponded, NoOp )

        GotoSignupClicked ->
            ( model, Cmd.none, RequestSignup )

        LoginResponded (Ok _) ->
            ( model, Cmd.none, LoggedInAs )

        LoginResponded (Err _) ->
            ( { model | error = Just "Login failed. Check your credentials." }, Cmd.none, NoOp )


view : Model -> List (Html Msg)
view model =
    [ h1 [ css [ textAlign center ] ] [ text "Login" ]
    , div [ css [ textAlign center ] ]
        [ div [ css [ display inlineBlock, textAlign left, padding (px 20), border3 (px 2) solid (hex "#00008b"), backgroundColor (hex "#f9f9f9") ] ]
            [ table []
                [ tr []
                    [ td [] [ text "Username:" ]
                    , td [] [ input [ type_ "text", value model.username, onInput UsernameChanged ] [] ]
                    ]
                , tr []
                    [ td [] [ text "Password:" ]
                    , td [] [ input [ type_ "password", value model.password, onInput PasswordChanged ] [] ]
                    ]
                , tr []
                    [ td [] [ button [ onClick SubmitClicked, css buttonStyle ] [ text "Login" ] ]
                    , td [] []
                    ]
                ]
            , viewError model.error
            , a [ onClick GotoSignupClicked, css [ textDecoration underline, display block, textAlign center ] ] [ text "No account? Signup" ]
            ]
        ]
    ]


viewError : Maybe String -> Html msg
viewError error =
    case error of
        Just message ->
            div [ css [ color (hex "#b00020"), textAlign center ] ] [ text message ]

        Nothing ->
            text ""
