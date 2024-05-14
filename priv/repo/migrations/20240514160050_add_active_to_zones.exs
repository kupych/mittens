defmodule Mittens.Repo.Migrations.AddActiveToZones do
  use Ecto.Migration

  def change do
    alter table(:zones) do
      add :active, :boolean, default: true
    end
  end
end
