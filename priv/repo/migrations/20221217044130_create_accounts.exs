defmodule Mittens.Repo.Migrations.CreateAccounts do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("accounts") do
      add :active, :boolean, default: true
      add :external_id, :string
      add :name, :string

      timestamps()
    end

    create_if_not_exists index(:accounts, :external_id)
  end
end
