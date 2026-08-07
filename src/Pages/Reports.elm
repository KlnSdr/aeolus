module Pages.Reports exposing (Model, Msg, init, update, userOf, view)

import ErrorHelper
import Html.Styled exposing (Html, div, text)
import Http exposing (Error)
import List exposing (map)
import RemoteData exposing (RemoteData(..), WebData)
import Reports exposing (Report, getAllReports)
import Users exposing (User)


userOf : Model -> Maybe User
userOf model =
    RemoteData.toMaybe model.user


type alias Model =
    { user : WebData User
    , reports : WebData (List Report)
    }


type Msg
    = UserResponded (Result Error User)
    | ReportsResponse (Result Error (List Report))


init : ( Model, Cmd Msg )
init =
    ( { user = Loading, reports = NotAsked }
    , Users.info UserResponded
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserResponded (Ok user) ->
            ( { model | user = Success user }, getAllReports ReportsResponse )

        UserResponded (Err _) ->
            ( model, Cmd.none )

        ReportsResponse (Ok reports) ->
            ( { model | reports = Success reports }, Cmd.none )

        ReportsResponse (Err reason) ->
            ( { model | reports = Failure reason }, Cmd.none )


view : Model -> List (Html Msg)
view model =
    [ div []
        [ case model.reports of
            Loading ->
                text "lade Berichte..."

            Success reports ->
                renderReports reports

            Failure reason ->
                reason |> ErrorHelper.errorToString |> text

            _ ->
                div [] []
        ]
    ]


renderReports : List Report -> Html Msg
renderReports reports =
    div [] (map renderReport reports)


renderReport : Report -> Html Msg
renderReport report =
    text report.name
