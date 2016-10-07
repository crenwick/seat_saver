
module SeatSaver exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)

import Json.Decode exposing ((:=))
import Json.Encode

import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push

socketServer : String
socketServer = "ws://localhost:4000/socket/websocket"

channelName : String
channelName = "seats:planner" 

main : Program Never
main =
  let
    channel = Phoenix.Channel.init channelName

    (initPhxServer, phxCmd) =
      Phoenix.Socket.init socketServer
        |> Phoenix.Socket.withDebug
        |> Phoenix.Socket.on "set_seats" channelName RecieveNewSeats
        |> Phoenix.Socket.on "seat_updated" channelName SeatChange
        |> Phoenix.Socket.join channel

    modelWithEffects =
        ( { seats = []
          , phxSocket = initPhxServer
          }
        , Cmd.map PhoenixMsg phxCmd)
  in
    App.program
      { init = modelWithEffects
      , view = view
      , update = update
      , subscriptions = subscriptions
      }

-- MODEL

type alias Seat =
  { seatNo : Int, occupied: Bool }

type alias Seats =
  List Seat

type alias Model =
  { seats : Seats
  , phxSocket : Phoenix.Socket.Socket Msg
  }

-- UPDATE

type Msg
  = Toggle Seat
  | PhoenixMsg (Phoenix.Socket.Msg Msg)
  | RecieveNewSeats Json.Encode.Value
  | SeatChange Json.Encode.Value

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Toggle seatToToggle ->
      let
        payload = encodeSeat seatToToggle
        push' =
          Phoenix.Push.init "request_seat" channelName
            |> Phoenix.Push.withPayload payload
            |> Phoenix.Push.onOk SeatChange
        ( phxSocket, phxCmd ) = Phoenix.Socket.push push' model.phxSocket
      in
        ( { model 
          | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )
    
    PhoenixMsg msg ->
      let
        ( phxSocket, phxCmd ) = Phoenix.Socket.update msg model.phxSocket
      in
        ( { model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )

    RecieveNewSeats raw ->
      case Json.Decode.decodeValue decodeSeats raw of
        Ok newSeats ->
          ( { model | seats = newSeats }
          , Cmd.none
          )
        Err error ->
          ( model, Cmd.none )

    SeatChange raw ->
      case Json.Decode.decodeValue decodeSeat raw of
        Ok newSeat ->
          let
            updateSeat seatFromModel =
              if seatFromModel.seatNo == newSeat.seatNo then
                { seatFromModel | occupied = newSeat.occupied }
              else seatFromModel
          in
            ( { model | seats = List.map updateSeat model.seats }
            , Cmd.none
            )
        Err error ->
          ( model, Cmd.none )

-- VIEW

view : Model -> Html Msg
view model =
  div []
    [ ul [ class "seats" ] (List.map seatItem model.seats)
    ]

seatItem : Seat -> Html Msg
seatItem seat =
  let
    occupiedClass =
      if seat.occupied then "occupied" else "available"
  in
    li
      [ class ("seat " ++ occupiedClass)
      , onClick (Toggle seat)
      ] 
      [ text (toString seat.seatNo) ]

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Phoenix.Socket.listen model.phxSocket PhoenixMsg

decodeSeat : Json.Decode.Decoder Seat
decodeSeat =
  Json.Decode.object2 (\seatNo occupied -> (Seat seatNo occupied))
    ("seatNo" := Json.Decode.int)
    ("occupied" := Json.Decode.bool)

decodeSeats : Json.Decode.Decoder Seats
decodeSeats =
  Json.Decode.at ["seats"] (Json.Decode.list decodeSeat)

encodeSeat : Seat -> Json.Decode.Value
encodeSeat seat =
  Json.Encode.object
    [ ("seatNo", Json.Encode.int seat.seatNo)
    , ("occupied", Json.Encode.bool seat.occupied)
    ]