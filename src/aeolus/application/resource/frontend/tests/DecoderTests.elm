module DecoderTests exposing (suite)

import Expect
import Json.Decode as Decode
import Messages
import Readings
import Test exposing (Test, describe, test)
import Users


readingDecoderTest : Test
readingDecoderTest =
    describe "Readings.decoder"
        [ test "decodes a well-formed reading" <|
            \_ ->
                """{"value": 21.5, "date": "2024-03-15"}"""
                    |> Decode.decodeString Readings.decoder
                    |> Expect.equal (Ok { value = 21.5, date = "2024-03-15" })
        , test "decodes an integer value as a float" <|
            \_ ->
                """{"value": 20, "date": "2024-03-15"}"""
                    |> Decode.decodeString Readings.decoder
                    |> Expect.equal (Ok { value = 20.0, date = "2024-03-15" })
        , test "fails when value is missing" <|
            \_ ->
                """{"date": "2024-03-15"}"""
                    |> Decode.decodeString Readings.decoder
                    |> Expect.err
        , test "fails when date is missing" <|
            \_ ->
                """{"value": 21.5}"""
                    |> Decode.decodeString Readings.decoder
                    |> Expect.err
        ]


userDecoderTest : Test
userDecoderTest =
    describe "Users.decoder"
        [ test "decodes a well-formed user" <|
            \_ ->
                """{"mail": "a@b.com", "displayName": "Alice", "id": "42"}"""
                    |> Decode.decodeString Users.decoder
                    |> Expect.equal (Ok { mail = "a@b.com", displayName = "Alice", id = "42" })
        , test "fails when a required field is missing" <|
            \_ ->
                """{"mail": "a@b.com", "id": "42"}"""
                    |> Decode.decodeString Users.decoder
                    |> Expect.err
        ]


messageDecoderTest : Test
messageDecoderTest =
    describe "Messages.decoder"
        [ test "decodes a well-formed message" <|
            \_ ->
                """{"id": "1", "message": "hi", "to": "a", "from": "b", "didRead": false, "dateSent": "12345"}"""
                    |> Decode.decodeString Messages.decoder
                    |> Expect.equal
                        (Ok
                            { id = "1"
                            , message = "hi"
                            , to = "a"
                            , from = "b"
                            , didRead = False
                            , dateSend = "12345"
                            }
                        )
        , test "fails when didRead is missing" <|
            \_ ->
                """{"id": "1", "message": "hi", "to": "a", "from": "b", "dateSent": "12345"}"""
                    |> Decode.decodeString Messages.decoder
                    |> Expect.err
        ]


suite : Test
suite =
    describe "Decoders"
        [ readingDecoderTest
        , userDecoderTest
        , messageDecoderTest
        ]
