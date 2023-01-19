defmodule Mittens.Dibs.Dib do
  @moduledoc """
  `Mittens.Dibs.Dib corresponds to a reservation
  of a server with a slack account for a given
  amount of time.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @fields [:account, :name, :expiry]

  schema "dibs" do
    field :account, :string
    field :expiry, :utc_datetime
    field :name, :string

    timestamps()
  end

  @doc """
  `changeset/2` returns a new `Ecto.Changeset` for a dib, after
  validating all required fields are presernt and all fields
  are valid.

  ## Example

      iex> attrs = %{account: "123", name: "develop", expiry: ~U[2022-01-01T00:00:00Z]}
      iex> Mittens.Dibs.Dib.changeset(%Mittens.Dibs.Dib{}, attrs)
      %Ecto.Changeset{valid?: true}
  """
  @spec changeset(dib :: t(), attrs :: map) :: Changeset.t()
  def changeset(%__MODULE__{} = dib, %{} = attrs) do
    dib
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end

  @doc """
  `changeset/1` returns a new `Ecto.Changeset` for a dib, after
  validating all required fields are present and all fields are
  valid.

  For example usage see `changeset/2`.
  """

  @spec changeset(attrs :: map) :: Changeset.t()
  def changeset(%{} = attrs), do: changeset(%__MODULE__{}, attrs)
end
