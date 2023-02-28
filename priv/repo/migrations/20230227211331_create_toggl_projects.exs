defmodule Mittens.Repo.Migrations.CreateTogglProjects do
  use Ecto.Migration

  def change do
    create table(:toggl_projects) do
      add :key, :string
      add :project_id, :string
      add :description, :string

      timestamps()
    end

    create_if_not_exists unique_index(:toggl_projects, :key)
  end
end
