module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Css exposing (..)
import Html.Styled exposing (Html, div, toUnstyled)
import Html.Styled.Attributes exposing (css)
import NavBar
import Pages.Dashboard as Dashboard
import Pages.Landing as Landing
import Pages.Login as Login
import Pages.MonthOverview as MonthOverview
import Pages.Signup as Signup
import Pages.YearOverview as YearOverview
import Route exposing (Route(..))
import Types exposing (User)
import Url exposing (Url)


type Page
    = Landing
    | LoginPage Login.Model
    | SignupPage Signup.Model
    | DashboardPage Dashboard.Model
    | MonthlyOverviewPage MonthOverview.Model
    | YearlyOverviewPage YearOverview.Model


type alias Model =
    { key : Nav.Key
    , page : Page
    , user : Maybe User
    }


type Msg
    = UrlChanged Url
    | LinkClicked Browser.UrlRequest
    | NavBarMsg NavBar.Msg
    | LoginMsg Login.Msg
    | SignupMsg Signup.Msg
    | DashboardMsg Dashboard.Msg
    | MonthOverviewMsg MonthOverview.Msg
    | YearOverviewMsg YearOverview.Msg


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    changeRouteTo (Route.fromUrl url) { key = key, page = Landing, user = Nothing }


changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    case maybeRoute of
        Nothing ->
            ( { model | page = Landing }, Cmd.none )

        Just Route.Landing ->
            ( { model | page = Landing, user = Nothing }, Cmd.none )

        Just Route.Login ->
            ( { model | page = LoginPage Login.init }, Cmd.none )

        Just Route.Signup ->
            ( { model | page = SignupPage Signup.init }, Cmd.none )

        Just Route.Dashboard ->
            let
                ( dashboardModel, dashboardCmd ) =
                    Dashboard.init
            in
            ( { model | page = DashboardPage dashboardModel }, Cmd.map DashboardMsg dashboardCmd )

        Just Route.MonthlyOverview ->
            let
                ( monthOverview, monthCmd ) =
                    MonthOverview.init
            in
            ( { model | page = MonthlyOverviewPage monthOverview }, Cmd.map MonthOverviewMsg monthCmd )

        Just Route.YearlyOverview ->
            let
                ( yearOverview, yearCmd ) =
                    YearOverview.init
            in
            ( { model | page = YearlyOverviewPage yearOverview }, Cmd.map YearOverviewMsg yearCmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged url ->
            changeRouteTo (Route.fromUrl url) model

        LinkClicked (Browser.Internal url) ->
            ( model, Nav.pushUrl model.key (Url.toString url) )

        LinkClicked (Browser.External href) ->
            ( model, Nav.load href )

        NavBarMsg NavBar.LogoutClicked ->
            ( model, Nav.pushUrl model.key (Route.toPath Route.Landing) )

        NavBarMsg NavBar.LoginClicked ->
            ( model, Nav.pushUrl model.key (Route.toPath Route.Login) )

        NavBarMsg (NavBar.NavElementClicked location) ->
            ( model, Nav.pushUrl model.key (Route.toPath location) )

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
                            ( model, Nav.pushUrl model.key (Route.toPath Route.Signup) )

                        Login.LoggedInAs ->
                            ( model, Nav.pushUrl model.key (Route.toPath Route.Dashboard) )

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
                            ( model, Nav.pushUrl model.key (Route.toPath Route.Login) )

                        Signup.SignedUp ->
                            ( model, Nav.pushUrl model.key (Route.toPath Route.Login) )

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

        MonthOverviewMsg subMsg ->
            case model.page of
                MonthlyOverviewPage subModel ->
                    let
                        ( newSubModel, subCmd ) =
                            MonthOverview.update subMsg subModel
                    in
                    ( { model | page = MonthlyOverviewPage newSubModel, user = MonthOverview.userOf newSubModel }
                    , Cmd.map MonthOverviewMsg subCmd
                    )

                _ ->
                    ( model, Cmd.none )

        YearOverviewMsg subMsg ->
            case model.page of
                YearlyOverviewPage subModel ->
                    let
                        ( newSubModel, subCmd ) =
                            YearOverview.update subMsg subModel
                    in
                    ( { model | page = YearlyOverviewPage newSubModel, user = YearOverview.userOf newSubModel }
                    , Cmd.map YearOverviewMsg subCmd
                    )

                _ ->
                    ( model, Cmd.none )


viewBody : Model -> Html Msg
viewBody model =
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


view : Model -> Browser.Document Msg
view model =
    { title = "Aeolus"
    , body = [ toUnstyled (viewBody model) ]
    }


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

        MonthlyOverviewPage subModel ->
            Html.Styled.map NavBarMsg (NavBar.navBar model.user)
                :: List.map (Html.Styled.map MonthOverviewMsg) (MonthOverview.view subModel)

        YearlyOverviewPage subModel ->
            Html.Styled.map NavBarMsg (NavBar.navBar model.user)
                :: List.map (Html.Styled.map YearOverviewMsg) (YearOverview.view subModel)
