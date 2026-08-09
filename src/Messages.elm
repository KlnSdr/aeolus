module Messages exposing (Message, getAllMessages, markAsRead, messagesOf)

import Constants exposing (api_url, token)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import RemoteData exposing (RemoteData(..), WebData)


type alias Message =
    { id : String
    , message : String
    , to : String
    , from : String
    , didRead : Bool
    , dateSend : String
    }


messagesOf : { a | messages : WebData (List Message) } -> List Message
messagesOf model =
    case model.messages of
        Success messages ->
            messages

        _ ->
            []


getAllMessages : (Result Http.Error (List Message) -> msg) -> Cmd msg
getAllMessages toMsg =
    Http.request
        { method = "GET"
        , url = api_url ++ "/rest/messages/unread"
        , headers = [ Http.header "Hades-Login-Token" token ]
        , expect = Http.expectJson toMsg (Decode.field "messages" (Decode.list messageDecoder))
        , body = Http.jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


markAsRead : String -> (Result Http.Error () -> msg) -> Cmd msg
markAsRead messageId toMsg =
    Http.request
        { method = "PUT"
        , url = api_url ++ "/rest/messages/read/" ++ messageId
        , headers = [ Http.header "Hades-Login-Token" token ]
        , expect = Http.expectWhatever toMsg
        , body = Http.jsonBody (Encode.object [])
        , timeout = Nothing
        , tracker = Nothing
        }


messageDecoder : Decoder Message
messageDecoder =
    Decode.succeed Message
        |> required "id" Decode.string
        |> required "message" Decode.string
        |> required "to" Decode.string
        |> required "from" Decode.string
        |> required "didRead" Decode.bool
        |> required "dateSent" Decode.string
