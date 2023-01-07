defmodule Mittens.Zones.Zone do
  @moduledoc """
  `Mittens.Zones.Zone corresponds to a Zone
  of responsibility within the mission
  control system. Generally linked
  with a` Mittens.Zones.Zone.`
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @fields [:description, :name, :slug]
  @required_fields [:name, :slug]

  schema "zones" do
    field :description, :string
    field :max_slots, :integer, default: 1
    field :name, :string
    field :slug, :string
    field :permanent, :boolean, default: false

    many_to_many(:accounts, Mittens.Accounts.Account,
      join_through: "accounts_zones",
      on_replace: :delete
    )

    timestamps()
  end

  @doc """
  `changeset/2` returns a new `Ecto.Changeset` for an zone, after
  validating all required fields are present and all fields are
  valid.

  ## Example

      iex> attrs = %{id: "id", name: "Mittens"}
      iex> Mittens.Zones.changeset(%Mittens.Zones.Zone{}, attrs}
      %Ecto.Changeset{valid?: true}
  """
  @spec changeset(zone :: t(), attrs :: map) :: Changeset.t()
  def changeset(%__MODULE__{} = zone, %{} = attrs) do
    zone
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  @doc """
  `changeset/1` returns a new `Ecto.Changeset` for an zone, after
  validating all required fields are present and all fields are
  valid.

  For example usage see `changeset/2`.
  """

  @spec changeset(attrs :: map) :: Changeset.t()
  def changeset(%{} = attrs), do: changeset(%__MODULE__{}, attrs)
end
