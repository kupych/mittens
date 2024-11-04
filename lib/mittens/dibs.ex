defmodule Mittens.Dibs do
  @moduledoc """
  `Mittens.Dibs` contains functions used by Dibby to reserve
  servers or determine which servers are reserved.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias Mittens.Dibs.Dib
  alias Mittens.Repo

  @doc """
  `delete_dib/1` deletes a dib. If the delete is successful,
  the deleted dib is returned, otherwise an error
  changeset is returned.
  """
  @spec delete_dib(dib :: Dib.t()) :: {:ok, Dib.t()} | {:error, Changeset.t()}
  def delete_dib(%Dib{} = dib) do
    Repo.delete(dib)
  end

  @doc """
  `get_dib/1` gets a dib given an ID.
  """
  @spec get_dib(id :: integer) :: Dib.t() | nil
  def get_dib(id) when is_integer(id) do
    Repo.get(Dib, id)
  end

  @doc """
  `get_dib_by_name/2` returns a dib given a server name. If the optional second
  parameter is set to `true`, includes expired dib, otherwise only returns
  non-expired dib.
  """
  @spec get_dib_by_name(name :: binary, include_expired? :: boolean) :: Dib.t() | nil
  def get_dib_by_name(name, include_expired? \\ false) when is_binary(name) do
    now = DateTime.utc_now()

    Dib
    |> where([d], d.name == ^name and (^include_expired? or d.expiry > ^now))
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  `list_dibs/1` returns a list of dibs.
  """
  @spec list_dibs(params :: list) :: [Dib.t()]
  def list_dibs(params) when is_list(params), do: Repo.all(Dib)

  @doc """
  `get_dibs_by_account/1` returns dibs given a slack account.
  """
  @spec get_dibs_by_account(account :: binary) :: [Dib.t()]
  def get_dibs_by_account(account) when is_binary(account) do
    Dib
    |> where([d], d.account == ^account)
    |> Repo.all()
  end

  @doc """
  `upsert_dib/2` creates or updates a dib provided the given
  attributes are valid. Returns the dib if successful,
  otherwise returns a changeset.
  """
  @spec upsert_dib(dib :: Dib.t(), attrs :: keyword | map) ::
          {:ok, Dib.t()} | {:error, Changeset.t()}
  def upsert_dib(%Dib{} = dib, attrs) when is_list(attrs) or is_map(attrs) do
    attrs
    |> Enum.into(%{})
    |> then(&Dib.changeset(dib, &1))
    |> then(&Multi.insert_or_update(Multi.new(), :dibs, &1))
    |> Repo.transaction()
  end

  def print_dib(%Dib{account: account, expiry: expiry, name: name}) do
    " is reserved by <@#{account}> until #{print_expiry(expiry)}"
  end

  def print_dib(_) do
    " is free!"
  end

  def print_undib(%Dib{account: account, name: name}) do
    "Unassigned <@#{account}> from `#{name}`"
  end

  defp print_expiry(%DateTime{} = expiry) do
    Timex.format!(expiry, "{Mfull} {D}")
  end
end
