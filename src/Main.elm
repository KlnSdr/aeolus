module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import CommonStyles exposing (buttonStyle)
import Components.Popup
import Css exposing (..)
import Dates exposing (formatEpochMillis)
import Html.Styled exposing (Html, button, div, hr, p, td, text, th, toUnstyled, tr)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (onClick)
import Http
import Messages exposing (Message, messagesOf)
import NavBar
import Pages.CompareYears as CompareYears
import Pages.Dashboard as Dashboard
import Pages.DataQuality as DataQuality
import Pages.Landing as Landing
import Pages.Login as Login
import Pages.MonthOverview as MonthOverview
import Pages.Reports as Reports
import Pages.Signup as Signup
import Pages.YearOverview as YearOverview
import RemoteData exposing (RemoteData(..))
import Route exposing (Route(..))
import Url exposing (Url)
import Users exposing (User)


type Page
    = Landing
    | LoginPage Login.Model
    | SignupPage Signup.Model
    | DashboardPage Dashboard.Model
    | MonthlyOverviewPage MonthOverview.Model
    | YearlyOverviewPage YearOverview.Model
    | CompareYearsPage CompareYears.Model
    | DataQualityPage DataQuality.Model
    | ReportsPage Reports.Model


pageToTitlePostFix : Page -> String
pageToTitlePostFix page =
    case page of
        Landing ->
            ""

        LoginPage _ ->
            " - Login"

        SignupPage _ ->
            " - Signup"

        DashboardPage _ ->
            ""

        MonthlyOverviewPage _ ->
            " - Monatsübersicht"

        YearlyOverviewPage _ ->
            " - Jahresübersicht"

        CompareYearsPage _ ->
            " - Vergleich"

        DataQualityPage _ ->
            " - Datenqualität"

        ReportsPage _ ->
            " -  Berichte"


type alias Model =
    { key : Nav.Key
    , page : Page
    , user : Maybe User
    , messages : List Message
    , messagesPopup : Components.Popup.Model Msg
    , messageDetailPopup : Components.Popup.Model Msg
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
    | CompareYearsMsg CompareYears.Msg
    | DataQualityMsg DataQuality.Msg
    | ReportsMsg Reports.Msg
    | MessagesPopupMsg (Components.Popup.Msg Msg)
    | MessageDetailPopupMsg (Components.Popup.Msg Msg)
    | OpenMessageDetail Message
    | MarkMessageAsRead Message
    | MessageMarkedAsRead String (Result Http.Error ())


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
    changeRouteTo (Route.fromUrl url)
        { key = key
        , page = Landing
        , user = Nothing
        , messages = []
        , messagesPopup = Components.Popup.closed
        , messageDetailPopup = Components.Popup.closed
        }


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

        Just Route.CompareYears ->
            let
                ( yearOverview, yearCmd ) =
                    CompareYears.init
            in
            ( { model | page = CompareYearsPage yearOverview }, Cmd.map CompareYearsMsg yearCmd )

        Just Route.DataQuality ->
            let
                ( dq, dqCmd ) =
                    DataQuality.init
            in
            ( { model | page = DataQualityPage dq }, Cmd.map DataQualityMsg dqCmd )

        Just Route.Reports ->
            let
                ( dq, dqCmd ) =
                    Reports.init
            in
            ( { model | page = ReportsPage dq }, Cmd.map ReportsMsg dqCmd )


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

        NavBarMsg NavBar.MessagesClicked ->
            ( { model | messagesPopup = Components.Popup.openReactive }, Cmd.none )

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
                    ( { model | page = DashboardPage newSubModel, user = Users.userOf newSubModel, messages = messagesOf newSubModel }
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
                    ( { model | page = MonthlyOverviewPage newSubModel, user = Users.userOf newSubModel, messages = messagesOf newSubModel }
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
                    ( { model | page = YearlyOverviewPage newSubModel, user = Users.userOf newSubModel, messages = messagesOf newSubModel }
                    , Cmd.map YearOverviewMsg subCmd
                    )

                _ ->
                    ( model, Cmd.none )

        CompareYearsMsg subMsg ->
            case model.page of
                CompareYearsPage subModel ->
                    let
                        ( newSubModel, subCmd ) =
                            CompareYears.update subMsg subModel
                    in
                    ( { model | page = CompareYearsPage newSubModel, user = Users.userOf newSubModel, messages = messagesOf newSubModel }
                    , Cmd.map CompareYearsMsg subCmd
                    )

                _ ->
                    ( model, Cmd.none )

        DataQualityMsg subMsg ->
            case model.page of
                DataQualityPage subModel ->
                    let
                        ( newSubModel, subCmd ) =
                            DataQuality.update subMsg subModel
                    in
                    ( { model | page = DataQualityPage newSubModel, user = Users.userOf newSubModel, messages = messagesOf newSubModel }
                    , Cmd.map DataQualityMsg subCmd
                    )

                _ ->
                    ( model, Cmd.none )

        ReportsMsg subMsg ->
            case model.page of
                ReportsPage subModel ->
                    let
                        ( newSubModel, subCmd ) =
                            Reports.update subMsg subModel
                    in
                    ( { model | page = ReportsPage newSubModel, user = Users.userOf newSubModel, messages = messagesOf newSubModel }
                    , Cmd.map ReportsMsg subCmd
                    )

                _ ->
                    ( model, Cmd.none )

        MessagesPopupMsg subMsg ->
            case subMsg of
                Components.Popup.ContentMsg contentMsg ->
                    update contentMsg { model | messagesPopup = Components.Popup.update subMsg model.messagesPopup }

                _ ->
                    ( { model | messagesPopup = Components.Popup.update subMsg model.messagesPopup }, Cmd.none )

        MessageDetailPopupMsg subMsg ->
            case subMsg of
                Components.Popup.ContentMsg contentMsg ->
                    update contentMsg { model | messageDetailPopup = Components.Popup.update subMsg model.messageDetailPopup }

                _ ->
                    ( { model | messageDetailPopup = Components.Popup.update subMsg model.messageDetailPopup }, Cmd.none )

        OpenMessageDetail message ->
            ( { model | messageDetailPopup = Components.Popup.open (messageDetailContent message) }, Cmd.none )

        MarkMessageAsRead message ->
            ( model, Messages.markAsRead message.id (MessageMarkedAsRead message.id) )

        MessageMarkedAsRead messageId result ->
            case result of
                Ok () ->
                    let
                        updatedMessages =
                            List.filter (\m -> m.id /= messageId) model.messages
                    in
                    ( { model
                        | messages = updatedMessages
                        , page = updatePageMessages updatedMessages model.page
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )


updatePageMessages : List Message -> Page -> Page
updatePageMessages messages page =
    case page of
        DashboardPage subModel ->
            DashboardPage { subModel | messages = Success messages }

        MonthlyOverviewPage subModel ->
            MonthlyOverviewPage { subModel | messages = Success messages }

        YearlyOverviewPage subModel ->
            YearlyOverviewPage { subModel | messages = Success messages }

        CompareYearsPage subModel ->
            CompareYearsPage { subModel | messages = Success messages }

        DataQualityPage subModel ->
            DataQualityPage { subModel | messages = Success messages }

        ReportsPage subModel ->
            ReportsPage { subModel | messages = Success messages }

        _ ->
            page


viewBody : Model -> Html Msg
viewBody model =
    div
        [ css
            [ margin (px 0)
            , padding (px 0)
            , backgroundColor (hex "#f9f9f9")
            , overflowX hidden
            , minHeight (vh 100)
            , fontFamilies [ "IBM Plex Sans", "sans-serif" ]
            ]
        ]
        (mainContent model)


view : Model -> Browser.Document Msg
view model =
    { title = "Aeolus" ++ pageToTitlePostFix model.page
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
            authenticatedNavbar model ++ List.map (Html.Styled.map DashboardMsg) (Dashboard.view subModel)

        MonthlyOverviewPage subModel ->
            authenticatedNavbar model ++ List.map (Html.Styled.map MonthOverviewMsg) (MonthOverview.view subModel)

        YearlyOverviewPage subModel ->
            authenticatedNavbar model ++ List.map (Html.Styled.map YearOverviewMsg) (YearOverview.view subModel)

        CompareYearsPage subModel ->
            authenticatedNavbar model ++ List.map (Html.Styled.map CompareYearsMsg) (CompareYears.view subModel)

        DataQualityPage subModel ->
            authenticatedNavbar model ++ List.map (Html.Styled.map DataQualityMsg) (DataQuality.view subModel)

        ReportsPage subModel ->
            authenticatedNavbar model ++ List.map (Html.Styled.map ReportsMsg) (Reports.view subModel)


authenticatedNavbar : Model -> List (Html Msg)
authenticatedNavbar model =
    [ Html.Styled.map NavBarMsg (NavBar.navBar model.user model.messages)
    , Html.Styled.map MessagesPopupMsg (Components.Popup.viewReactive (messagesPopupContent model.messages) model.messagesPopup)
    , Html.Styled.map MessageDetailPopupMsg (Components.Popup.view model.messageDetailPopup)
    ]


messagesPopupContent : List Message -> Html Msg
messagesPopupContent messages =
    case messages of
        [] ->
            p [] [ text "Keine ungelesenen Nachrichten." ]

        _ ->
            Html.Styled.table [ css messagesTableStyle ]
                (tr []
                    [ th [ css messagesTableCellStyle ] [ text "Von" ]
                    , th [ css messagesTableCellStyle ] [ text "Datum" ]
                    , th [ css messagesTableCellStyle ] [ text "Nachricht" ]
                    , th [ css messagesTableCellStyle ] []
                    , th [ css messagesTableCellStyle ] []
                    ]
                    :: List.map messageRow messages
                )


messageRow : Message -> Html Msg
messageRow message =
    tr []
        [ td [ css messagesTableCellStyle ] [ text message.from ]
        , td [ css messagesTableCellStyle ] [ text (formatEpochMillis message.dateSend) ]
        , td [ css messagesTableCellStyle ] [ text (truncateMessage message.message) ]
        , td [ css messagesTableCellStyle ] [ button [ css buttonStyle, onClick (OpenMessageDetail message) ] [ text "Öffnen" ] ]
        , td [ css messagesTableCellStyle ] [ button [ css buttonStyle, onClick (MarkMessageAsRead message) ] [ text "Als gelesen markieren" ] ]
        ]


truncateMessage : String -> String
truncateMessage content =
    String.left 6 content ++ "..."


messageDetailContent : Message -> Html Msg
messageDetailContent message =
    div []
        [ p [] [ text ("Von: " ++ message.from) ]
        , p [] [ text ("Datum: " ++ formatEpochMillis message.dateSend) ]
        , hr [] []
        , p [] [ text message.message ]
        ]


messagesTableStyle : List Style
messagesTableStyle =
    [ borderCollapse collapse
    , width (pct 100)
    ]


messagesTableCellStyle : List Style
messagesTableCellStyle =
    [ padding (px 6)
    , textAlign left
    , borderBottom3 (px 1) solid (hex "#dddddd")
    ]
