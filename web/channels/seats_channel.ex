defmodule SeatSaver.SeatsChannel do
  use SeatSaver.Web, :channel

  def join("seats:planner", payload, socket) do
    if authorized?(payload) do
      send self(), :after_join
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    seats = (from s in SeatSaver.Seat, order_by: [asc: s.seat_no]) |> Repo.all
    push socket, "set_seats", %{seats: seats}
    {:noreply, socket}
  end

  def handle_in("request_seat", payload, socket) do
    seat = Repo.get!(SeatSaver.Seat, payload["seatNo"])
    seat_params = %{occupied: !payload["occupied"]}
    changeset = SeatSaver.Seat.changeset(seat, seat_params)

    case Repo.update(changeset) do
      {:ok, seat} ->
        broadcast socket, "seat_updated", seat
        {:reply, {:ok, seat}, socket}
      {:error, _changeset} ->
        {:reply, {:error, %{message: "Something went wrong."}}, socket}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (seats:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
