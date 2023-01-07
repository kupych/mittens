defmodule Mittens.Repo.Migrations.AddMaxSlotsAndPermanentToZones do
  use Ecto.Migration

  def change do
    alter table(:zones) do
      add :max_slots, :integer, default: 1
      add :permanent, :boolean, default: false
    end
  end
end
