module MonthlyValuesTests exposing (suite)

import Expect
import Json.Decode as Decode
import MonthlyValues
    exposing
        ( Field(..)
        , allFields
        , fieldKey
        , fieldLabel
        , fieldUnit
        , fieldValue
        , tariffCentsOf
        , tariffFields
        )
import Test exposing (Test, describe, test)


monthlyValueJson : String
monthlyValueJson =
    """
    { "date": "2024-03"
    , "owner": "alice"
    , "operatingHoursHeating": 100
    , "operatingHoursWater": 50
    , "operatingHoursTwo": 0
    , "highTariffPower": 200
    , "lowTariffPower": 150
    , "householdPower": 300
    , "householdWater": 12
    , "tariffPrices":
        { "centsHighTariff": 25
        , "centsLowTariff": 15
        , "centsHouseholdPower": 20
        }
    }
    """


decoderTests : Test
decoderTests =
    describe "decoder"
        [ test "decodes a well-formed monthly value" <|
            \_ ->
                monthlyValueJson
                    |> Decode.decodeString MonthlyValues.decoder
                    |> Expect.equal
                        (Ok
                            { date = "2024-03"
                            , owner = "alice"
                            , operatingHoursHeating = 100
                            , operatingHoursWater = 50
                            , operatingHoursTwo = 0
                            , highTariffPower = 200
                            , lowTariffPower = 150
                            , householdPower = 300
                            , householdWater = 12
                            , tariffPrices =
                                { centsHighTariff = 25
                                , centsLowTariff = 15
                                , centsHouseholdPower = 20
                                }
                            }
                        )
        , test "fails when tariffPrices is missing" <|
            \_ ->
                """{"date":"2024-03","owner":"a","operatingHoursHeating":0,"operatingHoursWater":0,"operatingHoursTwo":0,"highTariffPower":0,"lowTariffPower":0,"householdPower":0,"householdWater":0}"""
                    |> Decode.decodeString MonthlyValues.decoder
                    |> Expect.err
        ]


sampleValue : MonthlyValues.MonthlyValue
sampleValue =
    { date = "2024-03"
    , owner = "alice"
    , operatingHoursHeating = 1
    , operatingHoursWater = 2
    , operatingHoursTwo = 3
    , highTariffPower = 4
    , lowTariffPower = 5
    , householdPower = 6
    , householdWater = 7
    , tariffPrices =
        { centsHighTariff = 10
        , centsLowTariff = 20
        , centsHouseholdPower = 30
        }
    }


fieldValueTests : Test
fieldValueTests =
    describe "fieldValue"
        [ test "reads operatingHoursHeating" <|
            \_ -> fieldValue OperatingHoursHeating sampleValue |> Expect.equal 1
        , test "reads operatingHoursWater" <|
            \_ -> fieldValue OperatingHoursWater sampleValue |> Expect.equal 2
        , test "reads highTariffPower" <|
            \_ -> fieldValue HighTariffPower sampleValue |> Expect.equal 4
        , test "reads householdWater" <|
            \_ -> fieldValue HouseholdWater sampleValue |> Expect.equal 7
        ]


tariffCentsOfTests : Test
tariffCentsOfTests =
    describe "tariffCentsOf"
        [ test "looks up the high-tariff price for HighTariffPower" <|
            \_ -> tariffCentsOf HighTariffPower sampleValue.tariffPrices |> Expect.equal 10
        , test "looks up the low-tariff price for LowTariffPower" <|
            \_ -> tariffCentsOf LowTariffPower sampleValue.tariffPrices |> Expect.equal 20
        , test "looks up the household price for HouseholdPower" <|
            \_ -> tariffCentsOf HouseholdPower sampleValue.tariffPrices |> Expect.equal 30
        , test "returns 0 for a field that isn't priced (e.g. operating hours)" <|
            \_ -> tariffCentsOf OperatingHoursHeating sampleValue.tariffPrices |> Expect.equal 0
        , test "returns 0 for HouseholdWater, which has no tariff price" <|
            \_ -> tariffCentsOf HouseholdWater sampleValue.tariffPrices |> Expect.equal 0
        ]


coverageTests : Test
coverageTests =
    describe "field metadata is defined for every field"
        [ test "every field has a non-empty key" <|
            \_ ->
                allFields
                    |> List.map fieldKey
                    |> List.all (\s -> String.length s > 0)
                    |> Expect.equal True
        , test "every field has a non-empty label" <|
            \_ ->
                allFields
                    |> List.map fieldLabel
                    |> List.all (\s -> String.length s > 0)
                    |> Expect.equal True
        , test "every field has a non-empty unit" <|
            \_ ->
                allFields
                    |> List.map fieldUnit
                    |> List.all (\s -> String.length s > 0)
                    |> Expect.equal True
        , test "tariffFields is a subset of allFields" <|
            \_ ->
                tariffFields
                    |> List.all (\f -> List.member f allFields)
                    |> Expect.equal True
        , test "field keys are unique" <|
            \_ ->
                let
                    keys =
                        List.map fieldKey allFields
                in
                (List.length keys == List.length (uniqueStrings keys))
                    |> Expect.equal True
        ]


uniqueStrings : List String -> List String
uniqueStrings list =
    List.foldl
        (\x acc ->
            if List.member x acc then
                acc

            else
                x :: acc
        )
        []
        list


suite : Test
suite =
    describe "MonthlyValues"
        [ decoderTests
        , fieldValueTests
        , tariffCentsOfTests
        , coverageTests
        ]
