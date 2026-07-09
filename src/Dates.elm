module Dates exposing (formatRataDie, fromRataDie, parseDateToRataDie, toRataDie)

import String exposing (fromInt)


parseDateToRataDie : String -> Maybe Int
parseDateToRataDie dateString =
    case String.split "-" dateString of
        [ yStr, mStr, dStr ] ->
            Maybe.map3 toRataDie
                (String.toInt yStr)
                (String.toInt mStr)
                (String.toInt dStr)

        _ ->
            Nothing


formatRataDie : Int -> String
formatRataDie n =
    let
        { day, month } =
            fromRataDie n

        pad x =
            String.padLeft 2 '0' (fromInt x)
    in
    pad day ++ "." ++ pad month


toRataDie : Int -> Int -> Int -> Int
toRataDie year month day =
    let
        y =
            if month <= 2 then
                year - 1

            else
                year

        era =
            (if y >= 0 then
                y

             else
                y - 399
            )
                // 400

        yoe =
            y - era * 400

        mp =
            modBy 12 (month + 9)

        doy =
            (153 * mp + 2) // 5 + day - 1

        doe =
            yoe * 365 + yoe // 4 - yoe // 100 + doy
    in
    era * 146097 + doe - 719468


fromRataDie : Int -> { year : Int, month : Int, day : Int }
fromRataDie z0 =
    let
        z =
            z0 + 719468

        era =
            (if z >= 0 then
                z

             else
                z - 146096
            )
                // 146097

        doe =
            z - era * 146097

        yoe =
            (doe - doe // 1460 + doe // 36524 - doe // 146096) // 365

        y =
            yoe + era * 400

        doy =
            doe - (365 * yoe + yoe // 4 - yoe // 100)

        mp =
            (5 * doy + 2) // 153

        day =
            doy - (153 * mp + 2) // 5 + 1

        month =
            if mp < 10 then
                mp + 3

            else
                mp - 9
    in
    { year =
        if month <= 2 then
            y + 1

        else
            y
    , month = month
    , day = day
    }
