module Types exposing (Reading, User)


type alias User =
    { mail : String
    , displayName : String
    , id : String
    }


type alias Reading =
    { value : Float
    , date : String
    }
