module Types exposing (..)

import Http


type alias User =
    { mail : String
    , displayName : String
    , id : String
    }


type alias LastReading =
    { value : Float
    , date : String
    }


type alias Model =
    { page : Page
    , user : Maybe User
    , lastReading : Maybe LastReading
    }


type Msg
    = Goto Page
    | Action Action
    | Response Responses


type Responses
    = LoginResponse (Result Http.Error String)
    | UserResponse (Result Http.Error User)
    | LastReadingResponse (Result Http.Error LastReading)


type Action
    = DoSignIn
    | DoSignUp


type Page
    = Landing
    | Main
    | Login
    | Signup
