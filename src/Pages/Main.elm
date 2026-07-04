module Pages.Main exposing (Model, Msg, init, update, userOf, view)

import Constants exposing (api_url, token)
import Html.Styled exposing (Html, div, h1, p, text)
import Http exposing (header, jsonBody, request)
import Json.Decode as Decode
import Json.Encode as Encode
import Round
import Types exposing (LastReading, User)


type alias Model =
    { user : Maybe User
    , lastReading : Maybe LastReading
    }


init : ( Model, Cmd Msg )
init =
    ( { user = Nothing, lastReading = Nothing }
    , doGetUserInfo
    )


userOf : Model -> Maybe User
userOf model =
    model.user


type Msg
    = UserResponded (Result Http.Error User)
    | LastReadingResponded (Result Http.Error LastReading)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserResponded (Ok user) ->
            ( { model | user = Just user }, getLastReading )

        UserResponded (Err _) ->
            ( model, Cmd.none )

        LastReadingResponded (Ok lastReading) ->
            ( { model | lastReading = Just lastReading }, Cmd.none )

        LastReadingResponded (Err _) ->
            ( model, Cmd.none )


view : Model -> List (Html Msg)
view model =
    [ div []
        [ h1 [] [ text (getLastReadingValue model.lastReading) ]
        , p [] [ text ("vom: " ++ getLastReadingDate model.lastReading) ]
        ]
    ]


getLastReadingValue : Maybe LastReading -> String
getLastReadingValue lastReading =
    case lastReading of
        Just val ->
            Round.round 1 val.value ++ " °C"

        Nothing ->
            "XY.Z °C"


getLastReadingDate : Maybe LastReading -> String
getLastReadingDate lastReading =
    case lastReading of
        Just val ->
            val.date

        Nothing ->
            "DD.MM.YYYY"


doGetUserInfo : Cmd Msg
doGetUserInfo =
    request
        { method = "GET"
        , url = api_url ++ "/rest/users/loginuserinfo"
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectJson UserResponded userInfoDecoder
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


userInfoDecoder : Decode.Decoder User
userInfoDecoder =
    Decode.map3 User
        (Decode.field "mail" Decode.string)
        (Decode.field "displayName" Decode.string)
        (Decode.field "id" Decode.string)


getLastReading : Cmd Msg
getLastReading =
    request
        { method = "GET"
        , url = api_url ++ "/rest/readings/last"
        , headers = [ header "Hades-Login-Token" token ]
        , expect = Http.expectJson LastReadingResponded lastReadingDecoder
        , body = jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


lastReadingDecoder : Decode.Decoder LastReading
lastReadingDecoder =
    Decode.map2 LastReading
        (Decode.field "value" Decode.float)
        (Decode.field "date" Decode.string)
