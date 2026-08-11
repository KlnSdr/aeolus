module Constants exposing (..)

import List.Extra


api_url : String
api_url =
    "http://localhost:3000/http://localhost:3333"


token : String
token =
    "1b698504-7ee2-49c5-b888-4ef414f5e0bab1f75f53-59f5-46e7-9532-d5cf6ec95bb793676725-819f-493a-93c0-a273d4cb0d38"


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
