module Pages.Reports exposing (Model, Msg, init, update, userOf, view)

import CommonStyles exposing (buttonStyle)
import Components.Popup
import Css exposing (absolute, backgroundColor, border3, bottom, color, displayFlex, flexFlow1, flexWrap, hex, hover, margin, marginBottom, marginTop, padding, position, property, px, relative, row, solid, width, wrap)
import ErrorHelper
import Html.Styled exposing (Html, button, div, h2, h3, input, label, li, option, p, select, text, ul)
import Html.Styled.Attributes exposing (css, type_)
import Html.Styled.Events exposing (onClick)
import Http exposing (Error)
import List exposing (map, sortWith)
import RemoteData exposing (RemoteData(..), WebData)
import Reports exposing (Report, ReportType(..), allReportFeatures, allReportSchedules, allReportTrigger, allReportTypes, deleteReport, getAllReports, render, reportFeatureToDisplayString, reportScheduleToDisplayString, reportTriggerToDisplayString, reportTypeToDisplayString)
import String exposing (fromInt, padLeft)
import Users exposing (User)


userOf : Model -> Maybe User
userOf model =
    RemoteData.toMaybe model.user


type alias Model =
    { user : WebData User
    , reports : WebData (List Report)
    , popup : Components.Popup.Model Msg
    }


type Msg
    = UserResponded (Result Error User)
    | ReportsResponse (Result Error (List Report))
    | DeleteReport Report
    | ReportDeleted (Result Error ())
    | RenderReport Report
    | PopupMsg (Components.Popup.Msg Msg)
    | OpenCreateReportPopup


init : ( Model, Cmd Msg )
init =
    ( { user = Loading, reports = NotAsked, popup = Components.Popup.closed }
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

        DeleteReport report ->
            ( model, deleteReport ReportDeleted report.id )

        ReportDeleted _ ->
            ( model, getAllReports ReportsResponse )

        RenderReport report ->
            ( model, render report )

        PopupMsg subMsg ->
            ( { model | popup = Components.Popup.update subMsg model.popup }, Cmd.none )

        OpenCreateReportPopup ->
            ( { model | popup = Components.Popup.open createNewReportPopup }, Cmd.none )


view : Model -> List (Html Msg)
view model =
    [ div []
        [ case model.reports of
            Loading ->
                text "lade Berichte..."

            Success reports ->
                div
                    [ css
                        [ margin (px 5)
                        ]
                    ]
                    [ button [ css buttonStyle, onClick OpenCreateReportPopup ] [ text "Bericht anlegen" ]
                    , renderReports reports
                    ]

            Failure reason ->
                reason |> ErrorHelper.errorToString |> text

            _ ->
                div [] []
        ]
    , Html.Styled.map PopupMsg (Components.Popup.view model.popup)
    ]


renderReports : List Report -> Html Msg
renderReports reports =
    div
        [ css
            [ displayFlex
            , flexFlow1 row
            , flexWrap wrap
            , marginTop (px 5)
            , property "gap" "5px"
            ]
        ]
        (map renderReport <| sortWith (\a -> \b -> compare a.name b.name) <| reports)


renderReport : Report -> Html Msg
renderReport report =
    div
        [ css
            [ padding (px 5)
            , border3 (px 2) solid (hex "#00008b")
            , position relative
            , padding (px 5)
            , width (px 400)
            ]
        ]
        [ h3 [] [ text report.name ]
        , div
            [ css
                []
            ]
            [ div
                [ css
                    [ property "display" "grid"
                    , property "grid-template-columns" "auto auto"
                    , property "grid-template-rows" "auto"
                    , property "grid-column-gap" "5px"
                    , property "grid-row-gap" "5px"
                    , Css.paddingBottom (px 15)
                    ]
                ]
                [ p [] [ text "Typ:" ]
                , p [] [ text <| reportTypeToDisplayString <| report.reportType ]
                , p [] [ text "Auslöser:" ]
                , p []
                    [ text <|
                        (reportTriggerToDisplayString report.trigger
                            ++ (if report.trigger == Reports.Schedule then
                                    " (" ++ reportScheduleToDisplayString report.scheduleDay ++ ", " ++ (report.scheduleHour |> fromInt |> padLeft 2 '0') ++ ":" ++ (report.scheduleMinute |> fromInt |> padLeft 2 '0') ++ ")"

                                else
                                    ""
                               )
                        )
                    ]
                , p [] [ text "Features:" ]
                , ul [] (report.reportFeatures |> map (\f -> li [] [ text <| reportFeatureToDisplayString <| f ]))
                ]
            , div
                [ css
                    [ displayFlex
                    , flexFlow1 row
                    , flexWrap wrap
                    , marginTop (px 5)
                    , property "gap" "5px"
                    , position absolute
                    , bottom (px 0)
                    , marginBottom (px 5)
                    ]
                ]
                [ button
                    [ css
                        [ border3 (px 2) solid (hex "#8B0000FF")
                        , backgroundColor (hex "#8B0000FF")
                        , color (hex "#f9f9f9")
                        , hover
                            [ backgroundColor (hex "#f9f9f9")
                            , color (hex "#8B0000FF")
                            ]
                        ]
                    , onClick (DeleteReport report)
                    ]
                    [ text "Löschen" ]
                , button [ css buttonStyle, onClick (RenderReport report) ] [ text "Jetzt auslösen" ]
                ]
            ]
        ]


createNewReportPopup : Html Msg
createNewReportPopup =
    div []
        [ h2 [] [ text "Neuer Bericht" ]
        , div
            [ css
                [ property "display" "grid"
                , property "grid-template-columns" "auto auto"
                , property "grid-template-rows" "auto"
                , property "grid-column-gap" "5px"
                , property "grid-row-gap" "5px"
                ]
            ]
            [ text "Name:"
            , input [] []
            , text "Typ:"
            , select [] (allReportTypes |> map (\reportType -> option [] [ text (reportTypeToDisplayString reportType ++ " (" ++ reportTypeAddition reportType ++ ")") ]))
            , p [] [ text "Auswertungen:" ]

            -- TODO labels for checkboxes
            , ul [] (allReportFeatures |> map (\feature -> div [] [ label [] [ input [ type_ "checkbox" ] [], text (reportFeatureToDisplayString feature) ] ]))
            , text "Auslöser:"
            , select [] (allReportTrigger |> map (\trigger -> option [] [ text (reportTriggerToDisplayString trigger) ]))
            , text "Tag:"
            , select [] (allReportSchedules |> map (\schedule -> option [] [ text (reportScheduleToDisplayString schedule) ]))
            , text "Uhrzeit (nicht eher als):"
            , input [ type_ "time" ] []
            ]
        , button [ css buttonStyle ] [ text "Speichern" ]
        ]


reportTypeAddition : ReportType -> String
reportTypeAddition reportType =
    case reportType of
        Monthly ->
            "Vormonat"

        Yearly ->
            "Vorjahr"
