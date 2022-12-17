defmodule Mittens.Accounts.Account do
  @moduledoc """
  `Mittens.Accounts.Account` corresponds to an
  account in Slack and its relevant display
  name.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @fields [:active, :external_id, :name]
  @required_fields [:external_id, :name]

  schema "accounts" do
    field :external_id, :string
    field :name, :string
    field :active, :boolean, default: true
  end

  @doc """
  `changeset/2` returns a new `Ecto.Changeset` for an account, after
  validating all required fields are present and all fields are
  valid.

  For example usage see `changeset/2`.

  ## Example

      iex> attrs = %{id: "id", name: "Mittens"}
      iex> Mittens.Accounts.changeset(%Mittens.Accounts.Account{}, attrs}
      %Ecto.Changeset{valid?: true}
  """
  @spec changeset(account :: t(), attrs :: map) :: Changeset.t()
  def changeset(%__MODULE__{} = account, %{} = attrs) do
    account
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  @doc """
  `changeset/1` returns a new `Ecto.Changeset` for an account, after
  validating all required fields are present and all fields are
  valid.

  For example usage see `changeset/2`.
  """

  @spec changeset(attrs :: map) :: Changeset.t()
  def changeset(%{} = attrs), do: changeset(%__MODULE__{}, attrs)
end
