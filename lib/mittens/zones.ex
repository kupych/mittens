defmodule Mittens.Zones do
  @moduledoc """
  `Mittens.Zones` contains utility functions for 
  the zones of responsibility.
  """

  import Ecto.Changeset
  import Ecto.Query

  alias Ecto.{Changeset, Multi}
  alias Ecto.Query.DynamicExpr
  alias Mittens.Accounts.Account
  alias Mittens.Repo
  alias Mittens.Zones.Zone

  @doc """
  `delete_zone/1` deletes a zone of responsibility.
  If the delete is successful, the deleted zone is
  returned, otherwise an error changeset is 
  returned.
  """
  @spec delete_zone(zone :: Zone.t()) :: {:ok, Zone.t()} | {:error, Changeset.t()}
  def delete_zone(%Zone{} = zone) do
    Repo.delete(zone)
  end

  @doc """
  `get_zone/1` gets a zone of responsibility given
  an ID.
  """
  @spec get_zone(id :: integer) :: Zone.t() | nil
  def get_zone(id) when is_integer(id) do
    Repo.get(Zone, id)
  end

  @doc """
  `get_zone_by_slug/1` returns a zone of responsibility
  given a slug.
  """
  @spec get_zone_by_slug(slug :: binary) :: Zone.t() | nil
  def get_zone_by_slug(slug) when is_binary(slug) do
    Zone
    |> where([z], z.slug == ^slug)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  `list_zones/1` queries the database for zones of responsibility
  matching the given criteria and returns a list.
  """
  @spec list_zones(filters :: keyword) :: [Zone.t()] | Enum.t()
  def list_zones(filters) when is_list(filters) do
    Zone
    |> where(^list_zones_where(filters))
    |> order_by([z], z.id)
    |> Repo.all()
  end

  @doc """
  `upsert_zone/2` creates or updates a zone of responsibility
  provided the given attributes are valid. Returns the zone
  if successful, otherwise returns a changeset.
  """
  @spec upsert_zone(zone :: Zone.t(), attrs :: keyword | map) ::
          {:ok, Zone.t()} | {:error, Changeset.t()}
  def upsert_zone(%Zone{} = zone, attrs) when is_list(attrs) or is_map(attrs) do
    attrs
    |> Enum.into(%{})
    |> then(&Zone.changeset(zone, &1))
    |> then(&Multi.insert_or_update(Multi.new(), :zone, &1))
    |> Repo.transaction()
  end

  @doc """
  `print_zone/1` prints the zone in a "slack-friendly" format with all the associated
  accounts, in the following format: 

  {ZONE NAME} ({ZONE ACCOUNT NAMES})join

  """
  @spec print_zone(zone :: Zone.t()) :: binary
  def print_zone(%Zone{} = zone) do
    accounts =
      case zone.accounts do
        [_ | _] = accounts -> accounts
        _ -> Repo.preload(zone, :accounts) |> Map.get(:accounts)
      end

    "#{zone.name} (#{print_accounts(accounts)})"
  end

  def shuffle_zones(dry_run? \\ true) do
    zones =
      [permanent?: false]
      |> list_zones()
      |> Repo.preload(:accounts)

    accounts =
      zones
      |> Enum.flat_map(& &1.accounts)
      |> Enum.shuffle()

    {_, changesets} = Enum.reduce(zones, {accounts, []}, &auto_assign_to_zone/2)

    if dry_run? do
      Enum.map(changesets, fn x -> x |> apply_changes() |> print_zone() end)
    else
      Enum.each(changesets, &Repo.update/1)
    end
  end

  def assign_account(%Zone{} = zone, %Account{} = account) do
    %{accounts: accounts} = zone = maybe_preload_accounts(zone)
    accounts = [account | accounts] |> Enum.uniq_by(& &1.id)

    zone
    |> Zone.changeset(%{})
    |> put_assoc(:accounts, accounts)
    |> Repo.update()
  end

  def unassign_account(%Zone{} = zone, %Account{} = account) do
    %{accounts: accounts} = zone = maybe_preload_accounts(zone)
    accounts = Enum.reject(accounts, & &1.id == account.id)

    zone
    |> Zone.changeset(%{})
    |> put_assoc(:accounts, accounts)
    |> Repo.update()
  end

  defp list_zones_where(filters) when is_list(filters) do
    Enum.reduce(filters, dynamic(true), fn
      {:permanent?, permanent?}, %DynamicExpr{} = dynamic when is_boolean(permanent?) ->
        dynamic([z], ^dynamic and z.permanent == ^permanent?)

      {:slug, slug}, %DynamicExpr{} = dynamic when is_binary(slug) ->
        dynamic([z], ^dynamic and z.slug == ^slug)

      {_, _}, %DynamicExpr{} = dynamic ->
        dynamic
    end)
  end

  defp print_accounts(accounts) when is_list(accounts) do
    accounts
    |> Enum.map(&print_account/1)
    |> Enum.join(", ")
  end

  defp print_account(%{external_id: id, name: name}) do
    "<@#{id}|#{name}>"
  end

  defp maybe_preload_accounts(%Zone{accounts: accounts} = zone) when is_list(accounts) do
    zone
  end

  defp maybe_preload_accounts(%Zone{} = zone) do
    Repo.preload(zone, :accounts)
  end

  defp auto_assign_to_zone(%Zone{} = zone, {accounts, changesets}) do
    count = Enum.count(zone.accounts)

    {to_add, accounts} = Enum.split(accounts, count)

    changeset =
      zone
      |> Zone.changeset(%{})
      |> put_assoc(:accounts, to_add)

    {accounts, [changeset | changesets]}
  end
end
