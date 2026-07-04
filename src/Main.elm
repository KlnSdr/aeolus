module Main exposing (main)

import Browser
import Css exposing (..)
import Html.Styled exposing (Html, div, toUnstyled)
import Html.Styled.Attributes exposing (css)
import NavBar
import Pages.Landing as Landing
import Pages.Login as Login
import Pages.Main as Dashboard
import Pages.Signup as Signup
import Types exposing (User)


type Page
    = Landing
    | LoginPage Login.Model
    | SignupPage Signup.Model
    | DashboardPage Dashboard.Model


type alias Model =
    { page : Page
    , user : Maybe User
    }


type Msg
    = GotoLanding
    | GotoLoginPage
    | GotoSignupPage
    | NavBarMsg NavBar.Msg
    | LoginMsg Login.Msg
    | SignupMsg Signup.Msg
    | DashboardMsg Dashboard.Msg


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view >> toUnstyled
        , subscriptions = \_ -> Sub.none
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { page = Landing, user = Nothing }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotoLanding ->
            ( { model | page = Landing, user = Nothing }, Cmd.none )

        GotoLoginPage ->
            ( { model | page = LoginPage Login.init }, Cmd.none )

        GotoSignupPage ->
            ( { model | page = SignupPage Signup.init }, Cmd.none )

        NavBarMsg navBarMsg ->
            case navBarMsg of
                NavBar.LogoutClicked ->
                    update GotoLanding model

                NavBar.LoginClicked ->
                    update GotoLoginPage model

        LoginMsg subMsg ->
            case model.page of
                LoginPage subModel ->
                    let
                        ( newSubModel, subCmd, out ) =
                            Login.update subMsg subModel
                    in
                    case out of
                        Login.NoOp ->
                            ( { model | page = LoginPage newSubModel }, Cmd.map LoginMsg subCmd )

                        Login.RequestSignup ->
                            ( { model | page = SignupPage Signup.init }, Cmd.none )

                        Login.LoggedInAs ->
                            let
                                ( dashboardModel, dashboardCmd ) =
                                    Dashboard.init
                            in
                            ( { model | page = DashboardPage dashboardModel }
                            , Cmd.map DashboardMsg dashboardCmd
                            )

                _ ->
                    -- A LoginMsg arriving while we're not on the login page
                    -- would mean a stale Cmd fired after the user navigated
                    -- away. Ignoring it is correct; logging would help spot
                    -- if it ever actually happens.
                    ( model, Cmd.none )

        SignupMsg subMsg ->
            case model.page of
                SignupPage subModel ->
                    let
                        ( newSubModel, subCmd, out ) =
                            Signup.update subMsg subModel
                    in
                    case out of
                        Signup.NoOp ->
                            ( { model | page = SignupPage newSubModel }, Cmd.map SignupMsg subCmd )

                        Signup.RequestLogin ->
                            ( { model | page = LoginPage Login.init }, Cmd.none )

                        Signup.SignedUp ->
                            update GotoLoginPage model

                _ ->
                    ( model, Cmd.none )

        DashboardMsg subMsg ->
            case model.page of
                DashboardPage subModel ->
                    let
                        ( newSubModel, subCmd ) =
                            Dashboard.update subMsg subModel
                    in
                    ( { model | page = DashboardPage newSubModel, user = Dashboard.userOf newSubModel }
                    , Cmd.map DashboardMsg subCmd
                    )

                _ ->
                    ( model, Cmd.none )


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


mainContent : Model -> List (Html Msg)
mainContent model =
    case model.page of
        Landing ->
            Html.Styled.map NavBarMsg NavBar.unauthNavBar :: Landing.view

        LoginPage subModel ->
            List.map (Html.Styled.map LoginMsg) (Login.view subModel)

        SignupPage subModel ->
            List.map (Html.Styled.map SignupMsg) (Signup.view subModel)

        DashboardPage subModel ->
            Html.Styled.map NavBarMsg (NavBar.navBar model.user)
                :: List.map (Html.Styled.map DashboardMsg) (Dashboard.view subModel)
