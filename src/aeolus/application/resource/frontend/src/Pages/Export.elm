module Pages.Export exposing (Model, Msg, init, update, view)

import CommonStyles exposing (buttonStyle)
import Components.Popup exposing (closed)
import Constants exposing (api_url)
import Css exposing (Style, bolder, center, em, fontSize, fontWeight, margin, marginTop, pct, px, textAlign)
import FeatherIcons exposing (download, toHtml)
import File.Download as Download
import Html.Styled exposing (Html, button, div, fromUnstyled, h1, h3, input, p, table, td, text, tr)
import Html.Styled.Attributes exposing (css, type_)
import Html.Styled.Events exposing (onClick, onInput)
import Http exposing (header, request)
import Messages exposing (Message, getAllMessages)
import Readings exposing (Reading)
import RemoteData exposing (RemoteData(..), WebData)
import Round
import Users exposing (User)


type alias Model =
    { user : WebData User
    , popup : Components.Popup.Model Msg
    , exportData : WebData String
    , messages : WebData (List Message)
    }


init : ( Model, Cmd Msg )
init =
    ( { user = Loading
      , popup = closed
      , exportData = NotAsked
      , messages = NotAsked
      }
    , Users.info UserResponded
    )


type Msg
    = UserResponded (Result Http.Error User)
    | PopupMsg (Components.Popup.Msg Msg)
    | MessagesResponse (Result Http.Error (List Message))
    | ExportResponse (Result Http.Error String)
    | DownloadCSV


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserResponded result ->
            ( Users.handleResponse result model
            , getAllMessages MessagesResponse
            )

        MessagesResponse response ->
            case response of
                Ok messages ->
                    ( { model | messages = Success messages, exportData = Loading }, getExport ExportResponse )

                Err err ->
                    ( { model | messages = Failure err, exportData = Loading }, getExport ExportResponse )

        PopupMsg (Components.Popup.ContentMsg subMsg) ->
            update subMsg model

        PopupMsg subMsg ->
            ( { model | popup = Components.Popup.update subMsg model.popup }, Cmd.none )

        ExportResponse response ->
            case response of
                Ok data ->
                    ( { model | exportData = Success data }, Cmd.none )

                Err err ->
                    ( { model | exportData = Failure err }, Cmd.none )

        DownloadCSV ->
            case model.exportData of
                Success data ->
                    ( model, Download.string "export.csv" "text/csv" data )

                _ ->
                    ( model, Cmd.none )


view : Model -> List (Html Msg)
view model =
    [ div [ css [ textAlign center, marginTop (pct 10) ] ]
        [ case model.exportData of
            NotAsked ->
                text "Export startet in Kürze"

            Loading ->
                text "Daten werden vorbereitet..."

            Failure _ ->
                text "Fehler beim Export"

            Success data ->
                button [ css buttonStyle, onClick DownloadCSV ] [ download |> FeatherIcons.withSize 12 |> toHtml [] |> fromUnstyled, text "Daten als CSV speichern" ]
        ]
    , Html.Styled.map PopupMsg (Components.Popup.view model.popup)
    ]


getExport : (Result Http.Error String -> msg) -> Cmd msg
getExport toMsg =
    request
        { method = "GET"
        , url = api_url ++ "/export"
        , headers =
            [ header "Accept" "text/csv"
            ]
        , expect = Http.expectString toMsg
        , body = Http.emptyBody
        , timeout = Nothing
        , tracker = Nothing
        }
