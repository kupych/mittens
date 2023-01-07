defmodule Mittens.Repo.Migrations.CreateZones do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("zones") do
      add :description, :string
      add :name, :string
      add :slug, :string

      timestamps()
    end

    create_if_not_exists index(:zones, :slug)
  end
end
