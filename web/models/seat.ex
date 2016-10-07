defmodule SeatSaver.Seat do
  use SeatSaver.Web, :model

  schema "seats" do
    field :seat_no, :integer
    field :occupied, :boolean, default: false

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:seat_no, :occupied])
    |> validate_required([:seat_no, :occupied])
  end
end
