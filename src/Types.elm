module Types exposing (LastReading, User)


type alias User =
    { mail : String
    , displayName : String
    , id : String
    }


type alias LastReading =
    { value : Float
    , date : String
    }
