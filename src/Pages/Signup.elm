module Pages.Signup exposing (Model, Msg(..), OutMsg(..), init, update, view)

import CommonStyles exposing (buttonStyle)
import Css exposing (backgroundColor, block, border3, center, color, display, hex, inlineBlock, left, padding, px, solid, textAlign, textDecoration, underline)
import Html.Styled exposing (Html, a, button, div, h1, input, table, td, text, tr)
import Html.Styled.Attributes exposing (css, type_, value)
import Html.Styled.Events exposing (onClick, onInput)


type alias Model =
    { username : String
    , email : String
    , password : String
    , repeatPassword : String
    , error : Maybe String
    }


init : Model
init =
    { username = "", email = "", password = "", repeatPassword = "", error = Nothing }


type Msg
    = UsernameChanged String
    | EmailChanged String
    | PasswordChanged String
    | RepeatPasswordChanged String
    | SubmitClicked
    | GotoLoginClicked


type OutMsg
    = NoOp
    | RequestLogin
    | SignedUp


update : Msg -> Model -> ( Model, Cmd Msg, OutMsg )
update msg model =
    case msg of
        UsernameChanged v ->
            ( { model | username = v }, Cmd.none, NoOp )

        EmailChanged v ->
            ( { model | email = v }, Cmd.none, NoOp )

        PasswordChanged v ->
            ( { model | password = v }, Cmd.none, NoOp )

        RepeatPasswordChanged v ->
            ( { model | repeatPassword = v }, Cmd.none, NoOp )

        SubmitClicked ->
            if model.password /= model.repeatPassword then
                ( { model | error = Just "Passwords do not match." }, Cmd.none, NoOp )

            else
                -- TODO: wire up the real signup endpoint once it exists.
                -- This mirrors the original code's placeholder behavior
                -- (there was no actual signup request before either).
                ( model, Cmd.none, SignedUp )

        GotoLoginClicked ->
            ( model, Cmd.none, RequestLogin )


view : Model -> List (Html Msg)
view model =
    [ h1 [ css [ textAlign center ] ] [ text "Signup" ]
    , div [ css [ textAlign center ] ]
        [ div [ css [ display inlineBlock, textAlign left, padding (px 20), border3 (px 2) solid (hex "#00008b"), backgroundColor (hex "#f9f9f9") ] ]
            [ table []
                [ tr []
                    [ td [] [ text "Username:" ]
                    , td [] [ input [ type_ "text", value model.username, onInput UsernameChanged ] [] ]
                    ]
                , tr []
                    [ td [] [ text "E-Mail:" ]
                    , td [] [ input [ type_ "text", value model.email, onInput EmailChanged ] [] ]
                    ]
                , tr []
                    [ td [] [ text "Password:" ]
                    , td [] [ input [ type_ "password", value model.password, onInput PasswordChanged ] [] ]
                    ]
                , tr []
                    [ td [] [ text "Repeat password:" ]
                    , td [] [ input [ type_ "password", value model.repeatPassword, onInput RepeatPasswordChanged ] [] ]
                    ]
                , tr []
                    [ td [] [ button [ onClick SubmitClicked, css buttonStyle ] [ text "Signup" ] ]
                    , td [] []
                    ]
                ]
            , viewError model.error
            , a [ onClick GotoLoginClicked, css [ textDecoration underline, display block, textAlign center ] ] [ text "Already have an account? Login" ]
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
