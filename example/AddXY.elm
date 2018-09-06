----------------------------------------------------------------------
--
-- AddXY.elm
-- The Elm frontend for the site/js/PortFunnel/AddXY.js backend.
-- Copyright (c) 2018 Bill St. Clair <billstclair@gmail.com>
-- Some rights reserved.
-- Distributed under the MIT License
-- See LICENSE.txt
--
----------------------------------------------------------------------


module AddXY exposing (Message, Response(..), State, initialState, makeModuleDesc)

import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE exposing (Value)
import PortFunnel exposing (GenericMessage, ModuleDesc)


type alias Sum =
    { x : Int
    , y : Int
    , sum : Int
    }


type alias State =
    List Sum


type Response
    = NoResponse
    | MessageResponse Message


type Message
    = AddMessage { x : Int, y : Int }
    | SumMessage Sum


initialState : State
initialState =
    []


moduleName : String
moduleName =
    "AddXY"


makeModuleDesc : (state -> State) -> (State -> state -> state) -> ModuleDesc msg Message state State Response
makeModuleDesc extractor injector =
    PortFunnel.makeModuleDesc moduleName
        encode
        decode
        extractor
        injector
        process


encode : Message -> GenericMessage
encode message =
    case message of
        AddMessage { x, y } ->
            GenericMessage moduleName
                "add"
            <|
                JE.object
                    [ ( "x", JE.int x )
                    , ( "y", JE.int y )
                    ]

        SumMessage { x, y, sum } ->
            GenericMessage moduleName
                "sum"
            <|
                JE.object
                    [ ( "x", JE.int x )
                    , ( "y", JE.int y )
                    , ( "sum", JE.int sum )
                    ]


addDecoder : Decoder Message
addDecoder =
    JD.map2 (\x y -> AddMessage { x = x, y = y })
        (JD.field "x" JD.int)
        (JD.field "y" JD.int)


sumDecoder : Decoder Message
sumDecoder =
    JD.map3 (\x y sum -> SumMessage { x = x, y = y, sum = sum })
        (JD.field "x" JD.int)
        (JD.field "y" JD.int)
        (JD.field "sum" JD.int)


decodeValue : Decoder x -> Value -> Result String x
decodeValue decoder value =
    case JD.decodeValue decoder value of
        Ok x ->
            Ok x

        Err err ->
            Err <| JD.errorToString err


decode : GenericMessage -> Result String Message
decode { tag, args } =
    case tag of
        "add" ->
            decodeValue addDecoder args

        "sum" ->
            decodeValue sumDecoder args

        _ ->
            Err <| "Unknown Echo tag: " ++ tag


process : (Message -> Cmd msg) -> Message -> State -> ( State, Response )
process messagePort message state =
    case message of
        SumMessage sum ->
            ( sum :: state, MessageResponse message )

        _ ->
            ( state, NoResponse )