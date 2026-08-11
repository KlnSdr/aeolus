module Pages.Dashboard exposing (Model, Msg, init, update, view)

import CommonStyles exposing (buttonStyle)
import Components.Popup exposing (closed)
import Css exposing (Style, bolder, center, em, fontSize, fontWeight, margin, marginTop, pct, px, textAlign)
import Html.Styled exposing (Html, button, div, h1, h3, input, p, table, td, text, tr)
import Html.Styled.Attributes exposing (css, type_)
import Html.Styled.Events exposing (onClick, onInput)
import Http
import Messages exposing (Message, getAllMessages)
import Readings exposing (Reading)
import RemoteData exposing (RemoteData(..), WebData)
import Round
import Users exposing (User)


type alias Model =
    { user : WebData User
    , lastReading : WebData Reading
    , popup : Components.Popup.Model Msg
    , manualEntryDate : String
    , manualEntryValue : String
    , messages : WebData (List Message)
    }


init : ( Model, Cmd Msg )
init =
    ( { user = Loading
      , lastReading = NotAsked
      , popup = closed
      , manualEntryDate = ""
      , manualEntryValue = ""
      , messages = NotAsked
      }
    , Users.info UserResponded
    )


type Msg
    = UserResponded (Result Http.Error User)
    | LastReadingResponded (Result Http.Error Reading)
    | PopupMsg (Components.Popup.Msg Msg)
    | OpenEnterManualValuesPopup
    | DateChanged String
    | ValueChanged String
    | SubmitManualValue
    | ReadingAdded (Result Http.Error ())
    | MessagesResponse (Result Http.Error (List Message))


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
                    ( { model | messages = Success messages }, Readings.last LastReadingResponded )

                Err err ->
                    ( { model | messages = Failure err }, Readings.last LastReadingResponded )

        LastReadingResponded result ->
            ( { model | lastReading = RemoteData.fromResult result }, Cmd.none )

        PopupMsg (Components.Popup.ContentMsg subMsg) ->
            update subMsg model

        PopupMsg subMsg ->
            ( { model | popup = Components.Popup.update subMsg model.popup }, Cmd.none )

        OpenEnterManualValuesPopup ->
            ( { model | popup = Components.Popup.open showEnterDetailsPopup }, Cmd.none )

        DateChanged value ->
            ( { model | manualEntryDate = value }, Cmd.none )

        ValueChanged value ->
            ( { model | manualEntryValue = value }, Cmd.none )

        SubmitManualValue ->
            ( { model | popup = closed }, Readings.uploadValue model.manualEntryDate model.manualEntryValue ReadingAdded )

        ReadingAdded res ->
            case res of
                Ok () ->
                    ( { model | popup = closed }, Readings.last LastReadingResponded )

                Err (Http.BadStatus 409) ->
                    ( model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )


view : Model -> List (Html Msg)
view model =
    [ div [ css [ textAlign center, marginTop (pct 10) ] ]
        (viewLastReading model.lastReading
            ++ [ button [ css buttonStyle, onClick OpenEnterManualValuesPopup ] [ text "Daten manuell Eintragen" ] ]
        )
    , Html.Styled.map PopupMsg (Components.Popup.view model.popup)
    ]


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


showEnterDetailsPopup : Html Msg
showEnterDetailsPopup =
    div []
        [ h3 [] [ text "Daten eintragen" ]
        , table []
            [ tr []
                [ td []
                    [ text "Datum" ]
                , td
                    []
                    [ input [ type_ "date", onInput DateChanged ] [] ]
                ]
            , tr []
                [ td []
                    [ text "Temperatur:" ]
                , td
                    []
                    [ input [ type_ "number", onInput ValueChanged ] [] ]
                ]
            , tr []
                [ td []
                    [ button [ css buttonStyle, onClick SubmitManualValue ] [ text "speichern" ] ]
                ]
            ]
        ]
