defmodule Mittens.Repo.Migrations.CreateDibs do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("dibs") do
      add :account, :string
      add :expiry, :utc_datetime
      add :name, :string

      timestamps()
    end

    create_if_not_exists index(:dibs, :account)
    create_if_not_exists unique_index(:dibs, :name)
  end
end
