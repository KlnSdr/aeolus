module Constants exposing (..)

import List.Extra


api_url : String
api_url =
    "{{CONTEXT}}"


months : List String
months =
    [ "Januar"
    , "Februar"
    , "März"
    , "April"
    , "Mai"
    , "Juni"
    , "Juli"
    , "August"
    , "September"
    , "Oktober"
    , "November"
    , "Dezember"
    ]


monthToInt : String -> Int
monthToInt month =
    case List.Extra.elemIndex month months of
        Just val ->
            val + 1

        Nothing ->
            -1


intToMonth : Int -> String
intToMonth index =
    case
        months
            |> List.drop index
            |> List.head
    of
        Just month ->
            month

        Nothing ->
            ""
