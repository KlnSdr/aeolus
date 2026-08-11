module Pages.MonthlyValues exposing (Model, Msg, init, update, view)

import CommonStyles exposing (buttonStyle)
import Components.MonthlyValuesChart as Chart
import Components.Popup
import Constants exposing (intToMonth)
import Css exposing (Style, backgroundColor, bolder, border3, center, color, displayFlex, fontWeight, hex, hover, justifyContent, margin, marginBottom, marginRight, marginTop, padding, property, px, solid)
import FeatherIcons
import Html.Styled exposing (Html, button, div, fromUnstyled, h1, h2, h3, input, label, table, td, text, th, tr)
import Html.Styled.Attributes exposing (css, type_, value)
import Html.Styled.Events exposing (onCheck, onClick, onInput)
import Http
import List.Extra
import Messages exposing (Message, getAllMessages)
import MonthlyValues exposing (Field(..), MonthlyValue, TariffPrices)
import RemoteData exposing (RemoteData(..), WebData)
import Round
import String
import Users exposing (User)


type alias Model =
    { user : WebData User
    , messages : WebData (List Message)
    , readings : WebData (List MonthlyValue)
    , popup : Components.Popup.Model Msg
    , entryForm : EntryForm
    , maintenanceForm : MaintenanceForm
    , tariffForm : TariffForm
    , tariffYear : String
    , reopenTariffYear : Maybe String
    }


type alias EntryForm =
    { date : String
    , operatingHoursHeating : String
    , operatingHoursWater : String
    , operatingHoursTwo : String
    , highTariffPower : String
    , lowTariffPower : String
    , householdPower : String
    , householdWater : String
    }


emptyEntryForm : EntryForm
emptyEntryForm =
    { date = ""
    , operatingHoursHeating = ""
    , operatingHoursWater = ""
    , operatingHoursTwo = ""
    , highTariffPower = ""
    , lowTariffPower = ""
    , householdPower = ""
    , householdWater = ""
    }


type alias MaintenanceField =
    { value : String, enabled : Bool }


emptyMaintenanceField : MaintenanceField
emptyMaintenanceField =
    { value = "", enabled = False }


type alias MaintenanceForm =
    { operatingHoursHeating : MaintenanceField
    , operatingHoursWater : MaintenanceField
    , operatingHoursTwo : MaintenanceField
    , highTariffPower : MaintenanceField
    , lowTariffPower : MaintenanceField
    , householdPower : MaintenanceField
    , householdWater : MaintenanceField
    }


emptyMaintenanceForm : MaintenanceForm
emptyMaintenanceForm =
    { operatingHoursHeating = emptyMaintenanceField
    , operatingHoursWater = emptyMaintenanceField
    , operatingHoursTwo = emptyMaintenanceField
    , highTariffPower = emptyMaintenanceField
    , lowTariffPower = emptyMaintenanceField
    , householdPower = emptyMaintenanceField
    , householdWater = emptyMaintenanceField
    }


type alias TariffFieldForm =
    { eur : String, cents : String }


emptyTariffFieldForm : TariffFieldForm
emptyTariffFieldForm =
    { eur = "0", cents = "0000" }


type alias TariffForm =
    { highTariffPower : TariffFieldForm
    , lowTariffPower : TariffFieldForm
    , householdPower : TariffFieldForm
    }


emptyTariffForm : TariffForm
emptyTariffForm =
    { highTariffPower = emptyTariffFieldForm
    , lowTariffPower = emptyTariffFieldForm
    , householdPower = emptyTariffFieldForm
    }


defaultTariffPrices : TariffPrices
defaultTariffPrices =
    { centsHighTariff = 0, centsLowTariff = 0, centsHouseholdPower = 0 }


init : ( Model, Cmd Msg )
init =
    ( { user = Loading
      , messages = NotAsked
      , readings = NotAsked
      , popup = Components.Popup.closed
      , entryForm = emptyEntryForm
      , maintenanceForm = emptyMaintenanceForm
      , tariffForm = emptyTariffForm
      , tariffYear = ""
      , reopenTariffYear = Nothing
      }
    , Users.info UserResponded
    )


type Msg
    = UserResponded (Result Http.Error User)
    | MessagesResponse (Result Http.Error (List Message))
    | ReadingsResponded (Result Http.Error (List MonthlyValue))
    | PopupMsg (Components.Popup.Msg Msg)
    | OpenEntryPopup
    | EntryDateChanged String
    | EntryFieldChanged Field String
    | SubmitEntry
    | EntrySaved (Result Http.Error ())
    | OpenMaintenancePopup
    | MaintenanceValueChanged Field String
    | MaintenanceEnabledChanged Field Bool
    | SubmitMaintenance
    | MaintenanceSaved (Result Http.Error ())
    | OpenMonthDetailPopup MonthlyValue
    | OpenYearSumPopup String (List MonthlyValue)
    | OpenYearChartPopup String (List MonthlyValue)
    | OpenYearTariffPopup String (List MonthlyValue)
    | OpenTariffEditPopup String (List MonthlyValue)
    | TariffEuroChanged Field String
    | TariffCentsChanged Field String
    | SubmitTariff
    | TariffSaved (Result Http.Error ())
    | OpenTrendPopup (List MonthlyValue)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserResponded result ->
            ( Users.handleResponse result model, getAllMessages MessagesResponse )

        MessagesResponse response ->
            case response of
                Ok messages ->
                    ( { model | messages = Success messages }, MonthlyValues.getAll ReadingsResponded )

                Err err ->
                    ( { model | messages = Failure err }, MonthlyValues.getAll ReadingsResponded )

        ReadingsResponded result ->
            case result of
                Ok readings ->
                    case model.reopenTariffYear of
                        Just year ->
                            let
                                yearData =
                                    readings |> List.filter (\r -> String.left 4 r.date == year)
                            in
                            ( { model
                                | readings = Success readings
                                , reopenTariffYear = Nothing
                                , popup = Components.Popup.open (yearTariffPopupContent year yearData)
                              }
                            , Cmd.none
                            )

                        Nothing ->
                            ( { model | readings = Success readings }, Cmd.none )

                Err err ->
                    ( { model | readings = Failure err }, Cmd.none )

        PopupMsg (Components.Popup.ContentMsg subMsg) ->
            update subMsg model

        PopupMsg subMsg ->
            ( { model | popup = Components.Popup.update subMsg model.popup }, Cmd.none )

        OpenEntryPopup ->
            ( { model | entryForm = emptyEntryForm, popup = Components.Popup.open entryPopupContent }, Cmd.none )

        EntryDateChanged newDate ->
            ( { model | entryForm = setEntryDate newDate model.entryForm }, Cmd.none )

        EntryFieldChanged field newValue ->
            ( { model | entryForm = setEntryField field newValue model.entryForm }, Cmd.none )

        SubmitEntry ->
            case parseYearMonth model.entryForm.date of
                Just ( year, month ) ->
                    ( { model | popup = Components.Popup.closed }
                    , MonthlyValues.save EntrySaved year month (toEntry model.entryForm)
                    )

                Nothing ->
                    ( { model | popup = Components.Popup.closed }, Cmd.none )

        EntrySaved result ->
            case result of
                Ok () ->
                    ( model, MonthlyValues.getAll ReadingsResponded )

                Err _ ->
                    ( model, Cmd.none )

        OpenMaintenancePopup ->
            ( { model | maintenanceForm = emptyMaintenanceForm, popup = Components.Popup.open maintenancePopupContent }, Cmd.none )

        MaintenanceValueChanged field newValue ->
            ( { model | maintenanceForm = setMaintenanceValue field newValue model.maintenanceForm }, Cmd.none )

        MaintenanceEnabledChanged field enabled ->
            ( { model | maintenanceForm = setMaintenanceEnabled field enabled model.maintenanceForm }, Cmd.none )

        SubmitMaintenance ->
            ( { model | popup = Components.Popup.closed }
            , MonthlyValues.saveMaintenance MaintenanceSaved (toMaintenanceEntry model.maintenanceForm)
            )

        MaintenanceSaved _ ->
            ( model, MonthlyValues.getAll ReadingsResponded )

        OpenMonthDetailPopup monthlyValue ->
            ( { model | popup = Components.Popup.open (monthDetailPopupContent monthlyValue) }, Cmd.none )

        OpenYearSumPopup year yearData ->
            ( { model | popup = Components.Popup.open (yearSumPopupContent year yearData) }, Cmd.none )

        OpenYearChartPopup year yearData ->
            ( { model | popup = Components.Popup.open (yearChartPopupContent year yearData) }, Cmd.none )

        OpenYearTariffPopup year yearData ->
            ( { model | popup = Components.Popup.open (yearTariffPopupContent year yearData) }, Cmd.none )

        OpenTariffEditPopup year yearData ->
            let
                prices =
                    yearData |> List.head |> Maybe.map .tariffPrices |> Maybe.withDefault defaultTariffPrices
            in
            ( { model
                | tariffYear = year
                , tariffForm = tariffFormFrom prices
                , popup = Components.Popup.open (tariffEditPopupContent year (tariffFormFrom prices))
              }
            , Cmd.none
            )

        TariffEuroChanged field newValue ->
            let
                updatedForm =
                    setTariffEuro field newValue model.tariffForm
            in
            ( { model
                | tariffForm = updatedForm
                , popup = Components.Popup.open (tariffEditPopupContent model.tariffYear updatedForm)
              }
            , Cmd.none
            )

        TariffCentsChanged field newValue ->
            let
                updatedForm =
                    setTariffCents field newValue model.tariffForm
            in
            ( { model
                | tariffForm = updatedForm
                , popup = Components.Popup.open (tariffEditPopupContent model.tariffYear updatedForm)
              }
            , Cmd.none
            )

        SubmitTariff ->
            ( { model | popup = Components.Popup.closed }
            , MonthlyValues.saveTariffPrices TariffSaved model.tariffYear (toTariffPrices model.tariffForm)
            )

        TariffSaved result ->
            case result of
                Ok () ->
                    ( { model | reopenTariffYear = Just model.tariffYear }, MonthlyValues.getAll ReadingsResponded )

                Err _ ->
                    ( model, Cmd.none )

        OpenTrendPopup readings ->
            ( { model | popup = Components.Popup.open (trendPopupContent readings) }, Cmd.none )


setEntryDate : String -> EntryForm -> EntryForm
setEntryDate newDate form =
    { form | date = newDate }


setEntryField : Field -> String -> EntryForm -> EntryForm
setEntryField field newValue form =
    case field of
        OperatingHoursHeating ->
            { form | operatingHoursHeating = newValue }

        OperatingHoursWater ->
            { form | operatingHoursWater = newValue }

        OperatingHoursTwo ->
            { form | operatingHoursTwo = newValue }

        HighTariffPower ->
            { form | highTariffPower = newValue }

        LowTariffPower ->
            { form | lowTariffPower = newValue }

        HouseholdPower ->
            { form | householdPower = newValue }

        HouseholdWater ->
            { form | householdWater = newValue }


parseIntOr0 : String -> Int
parseIntOr0 str =
    String.toInt str |> Maybe.withDefault 0


toEntry : EntryForm -> MonthlyValues.MonthlyValueEntry
toEntry form =
    { date = form.date
    , operatingHoursHeating = parseIntOr0 form.operatingHoursHeating
    , operatingHoursWater = parseIntOr0 form.operatingHoursWater
    , operatingHoursTwo = parseIntOr0 form.operatingHoursTwo
    , highTariffPower = parseIntOr0 form.highTariffPower
    , lowTariffPower = parseIntOr0 form.lowTariffPower
    , householdPower = parseIntOr0 form.householdPower
    , householdWater = parseIntOr0 form.householdWater
    }


parseYearMonth : String -> Maybe ( Int, Int )
parseYearMonth date =
    case String.split "-" date of
        [ y, m, _ ] ->
            Maybe.map2 Tuple.pair (String.toInt y) (String.toInt m)

        _ ->
            Nothing


setMaintenanceValue : Field -> String -> MaintenanceForm -> MaintenanceForm
setMaintenanceValue field newValue form =
    let
        update_ f =
            { f | value = newValue }
    in
    case field of
        OperatingHoursHeating ->
            { form | operatingHoursHeating = update_ form.operatingHoursHeating }

        OperatingHoursWater ->
            { form | operatingHoursWater = update_ form.operatingHoursWater }

        OperatingHoursTwo ->
            { form | operatingHoursTwo = update_ form.operatingHoursTwo }

        HighTariffPower ->
            { form | highTariffPower = update_ form.highTariffPower }

        LowTariffPower ->
            { form | lowTariffPower = update_ form.lowTariffPower }

        HouseholdPower ->
            { form | householdPower = update_ form.householdPower }

        HouseholdWater ->
            { form | householdWater = update_ form.householdWater }


setMaintenanceEnabled : Field -> Bool -> MaintenanceForm -> MaintenanceForm
setMaintenanceEnabled field enabled form =
    let
        update_ f =
            { f | enabled = enabled }
    in
    case field of
        OperatingHoursHeating ->
            { form | operatingHoursHeating = update_ form.operatingHoursHeating }

        OperatingHoursWater ->
            { form | operatingHoursWater = update_ form.operatingHoursWater }

        OperatingHoursTwo ->
            { form | operatingHoursTwo = update_ form.operatingHoursTwo }

        HighTariffPower ->
            { form | highTariffPower = update_ form.highTariffPower }

        LowTariffPower ->
            { form | lowTariffPower = update_ form.lowTariffPower }

        HouseholdPower ->
            { form | householdPower = update_ form.householdPower }

        HouseholdWater ->
            { form | householdWater = update_ form.householdWater }


{-| Mirrors the original app's "temporary maintenance" contract:
a disabled field is sent as -1, meaning "leave this value unchanged".
-}
maintenanceIntValue : MaintenanceField -> Int
maintenanceIntValue field =
    if field.enabled then
        parseIntOr0 field.value

    else
        -1


toMaintenanceEntry : MaintenanceForm -> MonthlyValues.MaintenanceEntry
toMaintenanceEntry form =
    { operatingHoursHeating = maintenanceIntValue form.operatingHoursHeating
    , operatingHoursWater = maintenanceIntValue form.operatingHoursWater
    , operatingHoursTwo = maintenanceIntValue form.operatingHoursTwo
    , highTariffPower = maintenanceIntValue form.highTariffPower
    , lowTariffPower = maintenanceIntValue form.lowTariffPower
    , householdPower = maintenanceIntValue form.householdPower
    , householdWater = maintenanceIntValue form.householdWater
    }


tariffFieldFormOf : Field -> TariffForm -> TariffFieldForm
tariffFieldFormOf field form =
    case field of
        HighTariffPower ->
            form.highTariffPower

        LowTariffPower ->
            form.lowTariffPower

        HouseholdPower ->
            form.householdPower

        _ ->
            emptyTariffFieldForm


setTariffEuro : Field -> String -> TariffForm -> TariffForm
setTariffEuro field newValue form =
    case field of
        HighTariffPower ->
            { form | highTariffPower = setEuro newValue form.highTariffPower }

        LowTariffPower ->
            { form | lowTariffPower = setEuro newValue form.lowTariffPower }

        HouseholdPower ->
            { form | householdPower = setEuro newValue form.householdPower }

        _ ->
            form


setTariffCents : Field -> String -> TariffForm -> TariffForm
setTariffCents field newValue form =
    case field of
        HighTariffPower ->
            { form | highTariffPower = setCents newValue form.highTariffPower }

        LowTariffPower ->
            { form | lowTariffPower = setCents newValue form.lowTariffPower }

        HouseholdPower ->
            { form | householdPower = setCents newValue form.householdPower }

        _ ->
            form


setEuro : String -> TariffFieldForm -> TariffFieldForm
setEuro newValue f =
    { f | eur = newValue }


setCents : String -> TariffFieldForm -> TariffFieldForm
setCents newValue f =
    { f | cents = newValue }


displayTariff : Int -> String
displayTariff cents =
    Round.round 4 (toFloat cents * 0.0001)


tariffFormFrom : TariffPrices -> TariffForm
tariffFormFrom prices =
    { highTariffPower = splitTariff prices.centsHighTariff
    , lowTariffPower = splitTariff prices.centsLowTariff
    , householdPower = splitTariff prices.centsHouseholdPower
    }


splitTariff : Int -> TariffFieldForm
splitTariff cents =
    case String.split "." (displayTariff cents) of
        [ eur, centsPart ] ->
            { eur = eur, cents = centsPart }

        _ ->
            { eur = "0", cents = "0000" }


toCents : TariffFieldForm -> Int
toCents f =
    case String.toFloat (f.eur ++ "." ++ f.cents) of
        Just v ->
            round (v * 10000)

        Nothing ->
            0


toTariffPrices : TariffForm -> TariffPrices
toTariffPrices form =
    { centsHighTariff = toCents form.highTariffPower
    , centsLowTariff = toCents form.lowTariffPower
    , centsHouseholdPower = toCents form.householdPower
    }


{-| Groups readings by the year of their date (YYYY-MM-DD), newest year first,
mirroring the original app's year-by-year listing.
-}
groupByYear : List MonthlyValue -> List ( String, List MonthlyValue )
groupByYear readings =
    readings
        |> List.Extra.gatherEqualsBy (\r -> String.left 4 r.date)
        |> List.map (\( first, rest ) -> ( String.left 4 first.date, first :: rest ))
        |> List.sortBy Tuple.first
        |> List.reverse


monthNameOf : String -> String
monthNameOf date =
    date
        |> String.slice 5 7
        |> String.toInt
        |> Maybe.map (\m -> intToMonth (m - 1))
        |> Maybe.withDefault ""


view : Model -> List (Html Msg)
view model =
    [ div [ css [ displayFlex, justifyContent center ] ]
        [ div [ css [ margin (px 5) ] ]
            [ button [ css (buttonStyle ++ [ marginRight (px 5) ]), onClick OpenEntryPopup ] [ text "Monatswerte eintragen" ]
            , button [ css (buttonStyle ++ [ marginRight (px 5) ]), onClick OpenMaintenancePopup ] [ text "Wartung" ]
            , case model.readings of
                Success readings ->
                    button [ css buttonStyle, onClick (OpenTrendPopup readings) ] [ text "Trend" ]

                _ ->
                    text ""
            , viewYears model.readings
            ]
        , Html.Styled.map PopupMsg (Components.Popup.view model.popup)
        ]
    ]


viewYears : WebData (List MonthlyValue) -> Html Msg
viewYears remote =
    case remote of
        Success readings ->
            div [] (groupByYear readings |> List.map viewYearSection)

        Failure _ ->
            text "Fehler beim Laden der Monatswerte."

        _ ->
            text "Lade Monatswerte..."


viewYearSection : ( String, List MonthlyValue ) -> Html Msg
viewYearSection ( year, yearData ) =
    div []
        [ div [ css yearHeadingContainerStyle ]
            [ h1 [] [ text year ]
            , button [ css yearButtonStyle, onClick (OpenYearSumPopup year yearData) ] [ iconHtml FeatherIcons.grid ]
            , button [ css yearButtonStyle, onClick (OpenYearChartPopup year yearData) ] [ iconHtml FeatherIcons.barChart2 ]
            , button [ css yearButtonStyle, onClick (OpenYearTariffPopup year yearData) ] [ iconHtml FeatherIcons.dollarSign ]
            ]
        , div [ css yearSectionStyle ] (yearData |> List.map viewMonthCard)
        ]


iconHtml : FeatherIcons.Icon -> Html msg
iconHtml icon =
    icon |> FeatherIcons.withSize 14 |> FeatherIcons.toHtml [] |> fromUnstyled


viewMonthCard : MonthlyValue -> Html Msg
viewMonthCard monthlyValue =
    div [ css cardStyle, onClick (OpenMonthDetailPopup monthlyValue) ]
        [ label [] [ text (monthNameOf monthlyValue.date) ] ]


monthDetailPopupContent : MonthlyValue -> Html Msg
monthDetailPopupContent monthlyValue =
    div []
        [ h2 [] [ text ("Monatswerte " ++ monthNameOf monthlyValue.date ++ " " ++ String.left 4 monthlyValue.date) ]
        , table []
            (MonthlyValues.allFields
                |> List.map
                    (\field ->
                        tr []
                            [ td [] [ text (MonthlyValues.fieldLabel field) ]
                            , td [] [ text (String.fromInt (MonthlyValues.fieldValue field monthlyValue)) ]
                            , td [] [ text (MonthlyValues.fieldUnit field) ]
                            ]
                    )
            )
        ]


entryPopupContent : Html Msg
entryPopupContent =
    div []
        [ h3 [] [ text "Monatswerte" ]
        , table []
            (tr []
                [ td [] [ text "Datum" ]
                , td [] [ input [ type_ "date", onInput EntryDateChanged ] [] ]
                ]
                :: (MonthlyValues.allFields
                        |> List.map
                            (\field ->
                                tr []
                                    [ td [] [ text (MonthlyValues.fieldLabel field) ]
                                    , td [] [ input [ type_ "number", onInput (EntryFieldChanged field) ] [] ]
                                    ]
                            )
                   )
            )
        , button [ css buttonStyle, onClick SubmitEntry ] [ text "speichern" ]
        ]


maintenancePopupContent : Html Msg
maintenancePopupContent =
    div []
        [ h2 [] [ text "Wartung vermerken" ]
        , table []
            (MonthlyValues.allFields
                |> List.map
                    (\field ->
                        tr []
                            [ td [] [ label [] [ text (MonthlyValues.fieldLabel field) ] ]
                            , td [] [ input [ type_ "number", onInput (MaintenanceValueChanged field) ] [] ]
                            , td [] [ input [ type_ "checkbox", onCheck (MaintenanceEnabledChanged field) ] [] ]
                            ]
                    )
            )
        , button [ css buttonStyle, onClick SubmitMaintenance ] [ text "speichern" ]
        ]


yearSumPopupContent : String -> List MonthlyValue -> Html Msg
yearSumPopupContent year yearData =
    div []
        [ h2 [] [ text ("Monatswerte " ++ year) ]
        , sumTable yearData
        ]


sumTable : List MonthlyValue -> Html Msg
sumTable yearData =
    table []
        (tr []
            (th [] [ text "" ]
                :: (Constants.months |> List.map (\m -> th [] [ text m ]))
                ++ [ th [] [ text "Summe" ] ]
            )
            :: (MonthlyValues.allFields |> List.map (sumRow yearData))
        )


sumRow : List MonthlyValue -> Field -> Html Msg
sumRow yearData field =
    let
        monthCells =
            List.range 0 11
                |> List.map
                    (\i ->
                        td []
                            [ yearData
                                |> List.Extra.getAt i
                                |> Maybe.map (MonthlyValues.fieldValue field >> String.fromInt)
                                |> Maybe.withDefault ""
                                |> text
                            ]
                    )

        total =
            yearData |> List.map (MonthlyValues.fieldValue field) |> List.sum
    in
    tr [] (td [] [ text (MonthlyValues.fieldLabel field) ] :: monthCells ++ [ td [] [ text (String.fromInt total) ] ])


yearChartPopupContent : String -> List MonthlyValue -> Html Msg
yearChartPopupContent year yearData =
    div [ css [ padding (px 30) ] ]
        [ h2 [] [ text ("Monatswerte " ++ year) ]
        , Chart.view (yearData |> List.indexedMap toChartPoint)
        ]


toChartPoint : Int -> MonthlyValue -> Chart.Point
toChartPoint index monthlyValue =
    { index = toFloat (index + 1)
    , label = monthlyValue.date |> String.slice 5 7
    , highTariffPower = toFloat monthlyValue.highTariffPower
    , lowTariffPower = toFloat monthlyValue.lowTariffPower
    , householdPower = toFloat monthlyValue.householdPower
    , operatingHoursHeating = toFloat monthlyValue.operatingHoursHeating
    , operatingHoursWater = toFloat monthlyValue.operatingHoursWater
    }


trendPopupContent : List MonthlyValue -> Html Msg
trendPopupContent readings =
    div [ css [ padding (px 35) ] ]
        [ h2 [] [ text "Jahrestrend" ]
        , Chart.view (yearlyAggregates readings)
        ]


yearlyAggregates : List MonthlyValue -> List Chart.Point
yearlyAggregates readings =
    groupByYear readings
        |> List.sortBy Tuple.first
        |> List.indexedMap
            (\index ( year, yearData ) ->
                { index = toFloat (index + 1)
                , label = year
                , highTariffPower = toFloat (List.sum (List.map .highTariffPower yearData))
                , lowTariffPower = toFloat (List.sum (List.map .lowTariffPower yearData))
                , householdPower = toFloat (List.sum (List.map .householdPower yearData))
                , operatingHoursHeating = toFloat (List.sum (List.map .operatingHoursHeating yearData))
                , operatingHoursWater = toFloat (List.sum (List.map .operatingHoursWater yearData))
                }
            )


yearTariffPopupContent : String -> List MonthlyValue -> Html Msg
yearTariffPopupContent year yearData =
    div []
        [ h2 [] [ text ("Kosten " ++ year) ]
        , button [ css buttonStyle, onClick (OpenTariffEditPopup year yearData) ] [ text "Tarif anpassen" ]
        , tariffTable yearData
        ]


tariffTable : List MonthlyValue -> Html Msg
tariffTable yearData =
    table []
        (tr []
            (th [] [ text "" ]
                :: th [] [ text "Tarif (€/kWh)" ]
                :: (Constants.months |> List.map (\m -> th [] [ text (m ++ " (kWh)") ]))
                ++ [ th [] [ text "Summe (€)" ] ]
            )
            :: (MonthlyValues.tariffFields |> List.map (tariffRow yearData))
        )


tariffRow : List MonthlyValue -> Field -> Html Msg
tariffRow yearData field =
    let
        priceCents =
            yearData
                |> List.head
                |> Maybe.map (\mv -> MonthlyValues.tariffCentsOf field mv.tariffPrices)
                |> Maybe.withDefault 0

        monthCells =
            List.range 0 11
                |> List.map
                    (\i ->
                        td []
                            [ yearData
                                |> List.Extra.getAt i
                                |> Maybe.map (MonthlyValues.fieldValue field >> String.fromInt)
                                |> Maybe.withDefault ""
                                |> text
                            ]
                    )

        total =
            yearData |> List.map (MonthlyValues.fieldValue field) |> List.sum

        sumEur =
            Round.round 2 (toFloat total * toFloat priceCents * 0.0001)
    in
    tr []
        (td [] [ text (MonthlyValues.fieldLabel field) ]
            :: td [] [ text (displayTariff priceCents) ]
            :: monthCells
            ++ [ td [] [ text sumEur ] ]
        )


tariffEditPopupContent : String -> TariffForm -> Html Msg
tariffEditPopupContent year form =
    div []
        [ h2 [] [ text ("Preise " ++ year) ]
        , table []
            (tr [] [ th [] [ text "" ], th [] [ text "Euro" ], th [] [ text "" ], th [] [ text "Cent" ] ]
                :: (MonthlyValues.tariffFields
                        |> List.map
                            (\field ->
                                let
                                    fieldForm =
                                        tariffFieldFormOf field form
                                in
                                tr []
                                    [ td [] [ text (MonthlyValues.fieldLabel field) ]
                                    , td [] [ input [ type_ "number", value fieldForm.eur, onInput (TariffEuroChanged field) ] [] ]
                                    , td [] [ text "," ]
                                    , td [] [ input [ type_ "number", value fieldForm.cents, onInput (TariffCentsChanged field) ] [] ]
                                    ]
                            )
                   )
            )
        , button [ css buttonStyle, onClick SubmitTariff ] [ text "speichern" ]
        ]


yearHeadingContainerStyle : List Style
yearHeadingContainerStyle =
    [ marginTop (px 10)
    , marginBottom (px 10)
    , displayFlex
    , property "align-items" "center"
    , property "gap" "5px"
    ]


yearButtonStyle : List Style
yearButtonStyle =
    buttonStyle
        ++ [ fontWeight bolder
           , property "width" "30px"
           , property "height" "30px"
           ]


yearSectionStyle : List Style
yearSectionStyle =
    [ displayFlex
    , property "flex-flow" "row wrap"
    , property "gap" "10px"
    ]


cardStyle : List Style
cardStyle =
    [ border3 (px 2) solid (hex "#00008b")
    , padding (px 5)
    , hover
        [ backgroundColor (hex "#00008b")
        , color (hex "#f9f9f9")
        ]
    ]
