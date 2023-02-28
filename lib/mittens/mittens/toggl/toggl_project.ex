defmodule Mittens.Toggl.TogglProject do
  use Ecto.Schema
  import Ecto.Changeset

  schema "toggl_projects" do
    field :description, :string
    field :key, :string
    field :project_id, :string

    timestamps()
  end

  @doc false
  def changeset(toggl_project, attrs) do
    toggl_project
    |> cast(attrs, [:key, :project_id, :description])
    |> validate_required([:key, :project_id])
  end
end
