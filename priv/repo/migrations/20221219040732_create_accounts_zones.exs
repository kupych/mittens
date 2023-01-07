defmodule Mittens.Repo.Migrations.CreateAccountsZones do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:accounts_zones, primary_key: false) do
      add(:account_id, references(:accounts, on_delete: :delete_all), primary_key: true)
      add(:zone_id, references(:zones, on_delete: :delete_all), primary_key: true)
      timestamps()
    end

    create_if_not_exists index(:accounts_zones, [:account_id])
    create_if_not_exists index(:accounts_zones, [:zone_id])
  end
end
