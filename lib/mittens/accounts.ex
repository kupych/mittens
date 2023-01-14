defmodule Mittens.Accounts do
  @moduledoc """
  `Mittens.Accounts` contains utility functions pertaining to
  accounts.
  """

  import Ecto.Query

  alias Ecto.{Changeset, Multi}
  alias Ecto.Query.DynamicExpr
  alias Mittens.Accounts.Account
  alias Mittens.Repo

  @doc """
  `delete_account/1` deletes an account.
  If the delete is successful, the deleted account is
  returned, otherwise an error changeset is 
  returned.
  """
  @spec delete_account(account :: Account.t()) :: {:ok, Account.t()} | {:error, Changeset.t()}
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  `get_account/1` gets a account given an ID
  an ID.
  """
  @spec get_account(id :: integer) :: Account.t() | nil
  def get_account(id) when is_integer(id) do
    Repo.get(Account, id)
  end

  @doc """
  `get_account_by_external_id/1` returns an account given the external ID.
  """
  @spec get_account_by_external_id(id :: binary) :: Account.t() | nil
  def get_account_by_external_id(id) when is_binary(id) do
    Account
    |> where([a], a.external_id == ^id)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  `list_accounts/1` queries the database for accounts of responsibility
  matching the given criteria and returns a list.
  """
  @spec list_accounts(filters :: keyword) :: [Account.t()] | Enum.t()
  def list_accounts(filters) when is_list(filters) do
    Account
    |> where(^list_accounts_where(filters))
    |> Repo.all()
  end

  @doc """
  `upsert_account/2` creates or updates a account provided
  the given attributes are valid. Returns the account
  if successful, otherwise returns a changeset.
  """
  @spec upsert_account(account :: Account.t(), attrs :: keyword | map) ::
          {:ok, Account.t()} | {:error, Changeset.t()}
  def upsert_account(%Account{} = account, attrs) when is_list(attrs) or is_map(attrs) do
    attrs
    |> Enum.into(%{})
    |> then(&Account.changeset(account, &1))
    |> then(&Multi.insert_or_update(Multi.new(), :account, &1))
    |> Repo.transaction()
  end

  defp list_accounts_where(filters) when is_list(filters) do
    Enum.reduce(filters, dynamic(true), fn
      {:external_id, id}, %DynamicExpr{} = dynamic when is_binary(id) ->
        dynamic([a], ^dynamic and a.external_id == ^id)
      {_, _}, %DynamicExpr{} = dynamic -> 
        dynamic
    end)
  end
end
