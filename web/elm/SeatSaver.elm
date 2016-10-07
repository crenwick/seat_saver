
module SeatSaver exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (class)
import Html.Events exposing (..)
import Http
import Json.Decode as Json exposing ((:=))
import Task

main : Program Never
main =
  App.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL

type alias Seat =
  { seatNo : Int, occupied: Bool }

type alias Model =
  List Seat

init : (Model, Cmd Msg)
init =
  let
    seats =
      [ { seatNo = 1, occupied = False }
      , { seatNo = 2, occupied = False }
      , { seatNo = 3, occupied = False }
      , { seatNo = 4, occupied = False }
      , { seatNo = 5, occupied = False }
      , { seatNo = 6, occupied = False }
      , { seatNo = 7, occupied = False }
      , { seatNo = 8, occupied = False }
      , { seatNo = 9, occupied = False }
      , { seatNo = 10, occupied = False }
      , { seatNo = 11, occupied = False }
      , { seatNo = 12, occupied = False }
      ]
  in
    (seats, fetchSeats)

-- UPDATE

type Msg
  = Toggle Seat
  | SeatSeats Model
  | FetchFail Http.Error

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Toggle seatToToggle ->
      let updateSeat seatFromModel =
        if seatFromModel.seatNo == seatToToggle.seatNo then
          { seatFromModel | occupied = not seatFromModel.occupied }
        else seatFromModel
      in
        (List.map updateSeat model, Cmd.none)

    SeatSeats newModel ->
      (newModel, Cmd.none)

    FetchFail _ ->
      (model, Cmd.none)

-- VIEW

view : Model -> Html Msg
view model =
  ul [ class "seats" ] (List.map seatItem model)

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
  Sub.none

-- HTTP

fetchSeats : Cmd Msg
fetchSeats =
  let
    url = "http://localhost:4000/api/seats"
  in
    Task.perform FetchFail SeatSeats (Http.get decodeSeats url)

decodeSeats : Json.Decoder Model
decodeSeats =
  let
    seat =
      Json.object2 (\seatNo occupied -> (Seat seatNo occupied))
        ("seatNo" := Json.int)
        ("occupied" := Json.bool)
  in
    Json.at ["data"] (Json.list seat)