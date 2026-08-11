module MonthlyValues exposing
    ( Field(..)
    , MaintenanceEntry
    , MonthlyValue
    , MonthlyValueEntry
    , TariffPrices
    , allFields
    , decoder
    , fieldKey
    , fieldLabel
    , fieldUnit
    , fieldValue
    , getAll
    , save
    , saveMaintenance
    , saveTariffPrices
    , tariffCentsOf
    , tariffFields
    )

import Constants exposing (api_url)
import Http exposing (header, jsonBody, request)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import String exposing (fromInt)


type alias TariffPrices =
    { centsHighTariff : Int
    , centsLowTariff : Int
    , centsHouseholdPower : Int
    }


type alias MonthlyValue =
    { date : String
    , owner : String
    , operatingHoursHeating : Int
    , operatingHoursWater : Int
    , operatingHoursTwo : Int
    , highTariffPower : Int
    , lowTariffPower : Int
    , householdPower : Int
    , householdWater : Int
    , tariffPrices : TariffPrices
    }


type Field
    = OperatingHoursHeating
    | OperatingHoursWater
    | OperatingHoursTwo
    | HighTariffPower
    | LowTariffPower
    | HouseholdPower
    | HouseholdWater


allFields : List Field
allFields =
    [ OperatingHoursHeating
    , OperatingHoursWater
    , OperatingHoursTwo
    , HighTariffPower
    , LowTariffPower
    , HouseholdPower
    , HouseholdWater
    ]


tariffFields : List Field
tariffFields =
    [ HighTariffPower, LowTariffPower, HouseholdPower ]


fieldKey : Field -> String
fieldKey field =
    case field of
        OperatingHoursHeating ->
            "operatingHoursHeating"

        OperatingHoursWater ->
            "operatingHoursWater"

        OperatingHoursTwo ->
            "operatingHoursTwo"

        HighTariffPower ->
            "highTariffPower"

        LowTariffPower ->
            "lowTariffPower"

        HouseholdPower ->
            "householdPower"

        HouseholdWater ->
            "householdWater"


fieldLabel : Field -> String
fieldLabel field =
    case field of
        OperatingHoursHeating ->
            "Betriebsstunden Heizung"

        OperatingHoursWater ->
            "Betriebsstunden Wasser"

        OperatingHoursTwo ->
            "Betriebsstunden 2"

        HighTariffPower ->
            "Hochtarifstrom (1.81)"

        LowTariffPower ->
            "Niedertarifstrom (1.82)"

        HouseholdPower ->
            "Hausstrom"

        HouseholdWater ->
            "Wasser"


fieldUnit : Field -> String
fieldUnit field =
    case field of
        OperatingHoursHeating ->
            "h"

        OperatingHoursWater ->
            "h"

        OperatingHoursTwo ->
            "h"

        HighTariffPower ->
            "kW/h"

        LowTariffPower ->
            "kW/h"

        HouseholdPower ->
            "kW/h"

        HouseholdWater ->
            "m^3"


fieldValue : Field -> MonthlyValue -> Int
fieldValue field monthlyValue =
    case field of
        OperatingHoursHeating ->
            monthlyValue.operatingHoursHeating

        OperatingHoursWater ->
            monthlyValue.operatingHoursWater

        OperatingHoursTwo ->
            monthlyValue.operatingHoursTwo

        HighTariffPower ->
            monthlyValue.highTariffPower

        LowTariffPower ->
            monthlyValue.lowTariffPower

        HouseholdPower ->
            monthlyValue.householdPower

        HouseholdWater ->
            monthlyValue.householdWater


tariffCentsOf : Field -> TariffPrices -> Int
tariffCentsOf field prices =
    case field of
        HighTariffPower ->
            prices.centsHighTariff

        LowTariffPower ->
            prices.centsLowTariff

        HouseholdPower ->
            prices.centsHouseholdPower

        _ ->
            0


type alias MonthlyValueEntry =
    { date : String
    , operatingHoursHeating : Int
    , operatingHoursWater : Int
    , operatingHoursTwo : Int
    , highTariffPower : Int
    , lowTariffPower : Int
    , householdPower : Int
    , householdWater : Int
    }


type alias MaintenanceEntry =
    { operatingHoursHeating : Int
    , operatingHoursWater : Int
    , operatingHoursTwo : Int
    , highTariffPower : Int
    , lowTariffPower : Int
    , householdPower : Int
    , householdWater : Int
    }


getAll : (Result Http.Error (List MonthlyValue) -> msg) -> Cmd msg
getAll toMsg =
    request
        { method = "GET"
        , url = api_url ++ "/rest/monthly-values"
        , headers = []
        , expect = Http.expectJson toMsg listDecoder
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


save : (Result Http.Error () -> msg) -> Int -> Int -> MonthlyValueEntry -> Cmd msg
save toMsg year month entry =
    request
        { method = "PUT"
        , url = api_url ++ "/rest/monthly-values/" ++ fromInt year ++ "/" ++ fromInt month
        , headers = [ header "Content-Type" "application/json" ]
        , body = jsonBody (encodeEntry entry)
        , expect = Http.expectStringResponse toMsg addResponseToResult
        , timeout = Nothing
        , tracker = Nothing
        }


saveMaintenance : (Result Http.Error () -> msg) -> MaintenanceEntry -> Cmd msg
saveMaintenance toMsg entry =
    request
        { method = "PUT"
        , url = api_url ++ "/rest/monthly-values/temporary"
        , headers = [ header "Content-Type" "application/json" ]
        , body = jsonBody (encodeMaintenanceEntry entry)
        , expect = Http.expectStringResponse toMsg addResponseToResult
        , timeout = Nothing
        , tracker = Nothing
        }


saveTariffPrices : (Result Http.Error () -> msg) -> String -> TariffPrices -> Cmd msg
saveTariffPrices toMsg year prices =
    request
        { method = "PUT"
        , url = api_url ++ "/rest/tariff-prices/" ++ year
        , headers = [ header "Content-Type" "application/json" ]
        , body = jsonBody (encodeTariffPrices prices)
        , expect = Http.expectStringResponse toMsg addResponseToResult
        , timeout = Nothing
        , tracker = Nothing
        }


addResponseToResult : Http.Response String -> Result Http.Error ()
addResponseToResult response =
    case response of
        Http.BadUrl_ url ->
            Err (Http.BadUrl url)

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError

        Http.BadStatus_ metadata _ ->
            Err (Http.BadStatus metadata.statusCode)

        Http.GoodStatus_ _ _ ->
            Ok ()


listDecoder : Decoder (List MonthlyValue)
listDecoder =
    Decode.field "readings" (Decode.list decoder)


decoder : Decoder MonthlyValue
decoder =
    Decode.succeed MonthlyValue
        |> required "date" Decode.string
        |> required "owner" Decode.string
        |> required "operatingHoursHeating" Decode.int
        |> required "operatingHoursWater" Decode.int
        |> required "operatingHoursTwo" Decode.int
        |> required "highTariffPower" Decode.int
        |> required "lowTariffPower" Decode.int
        |> required "householdPower" Decode.int
        |> required "householdWater" Decode.int
        |> required "tariffPrices" tariffPricesDecoder


tariffPricesDecoder : Decoder TariffPrices
tariffPricesDecoder =
    Decode.succeed TariffPrices
        |> required "centsHighTariff" Decode.int
        |> required "centsLowTariff" Decode.int
        |> required "centsHouseholdPower" Decode.int


encodeEntry : MonthlyValueEntry -> Encode.Value
encodeEntry entry =
    Encode.object
        [ ( "date", Encode.string entry.date )
        , ( "operatingHoursHeating", Encode.int entry.operatingHoursHeating )
        , ( "operatingHoursWater", Encode.int entry.operatingHoursWater )
        , ( "operatingHoursTwo", Encode.int entry.operatingHoursTwo )
        , ( "highTariffPower", Encode.int entry.highTariffPower )
        , ( "lowTariffPower", Encode.int entry.lowTariffPower )
        , ( "householdPower", Encode.int entry.householdPower )
        , ( "householdWater", Encode.int entry.householdWater )
        ]


encodeMaintenanceEntry : MaintenanceEntry -> Encode.Value
encodeMaintenanceEntry entry =
    Encode.object
        [ ( "operatingHoursHeating", Encode.int entry.operatingHoursHeating )
        , ( "operatingHoursWater", Encode.int entry.operatingHoursWater )
        , ( "operatingHoursTwo", Encode.int entry.operatingHoursTwo )
        , ( "highTariffPower", Encode.int entry.highTariffPower )
        , ( "lowTariffPower", Encode.int entry.lowTariffPower )
        , ( "householdPower", Encode.int entry.householdPower )
        , ( "householdWater", Encode.int entry.householdWater )
        ]


encodeTariffPrices : TariffPrices -> Encode.Value
encodeTariffPrices prices =
    Encode.object
        [ ( "centsHighTariff", Encode.int prices.centsHighTariff )
        , ( "centsLowTariff", Encode.int prices.centsLowTariff )
        , ( "centsHouseholdPower", Encode.int prices.centsHouseholdPower )
        ]
