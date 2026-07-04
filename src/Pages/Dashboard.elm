module Pages.Dashboard exposing (Model, Msg, init, update, userOf, view)

import Constants exposing (api_url, token)
import Html.Styled exposing (Html, div, h1, p, text)
import Http exposing (header, jsonBody, request)
import Json.Decode as Decode
import Json.Encode as Encode
import RemoteData exposing (RemoteData(..), WebData)
import Round
import Types exposing (LastReading, User)


type alias Model =
    { user : WebData User
    , lastReading : WebData LastReading
    }


init : ( Model, Cmd Msg )
init =
    ( { user = Loading, lastReading = NotAsked }
    , doGetUserInfo
    )


userOf : Model -> Maybe User
userOf model =
    RemoteData.toMaybe model.user


type Msg
    = UserResponded (Result Http.Error User)
    | LastReadingResponded (Result Http.Error LastReading)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserResponded result ->
            ( { model | user = RemoteData.fromResult result }
            , case result of
                Ok _ ->
                    getLastReading

                Err _ ->
                    Cmd.none
            )

        LastReadingResponded result ->
            ( { model | lastReading = RemoteData.fromResult result }, Cmd.none )


view : Model -> List (Html Msg)
view model =
    [ div [] (viewLastReading model.lastReading) ]


viewLastReading : WebData LastReading -> List (Html msg)
viewLastReading remoteReading =
    case remoteReading of
        NotAsked ->
            [ h1 [] [ text "XY.Z °C" ], p [] [ text "vom: DD.MM.YYYY" ] ]

        Loading ->
            [ h1 [] [ text "Loading..." ] ]

        Failure _ ->
            [ h1 [] [ text "Couldn't load the last reading." ] ]

        Success reading ->
            [ h1 [] [ text (Round.round 1 reading.value ++ " °C") ]
            , p [] [ text ("vom: " ++ reading.date) ]
            ]


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
