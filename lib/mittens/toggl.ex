defmodule Mittens.Toggl do
  @moduledoc """
  Integrations for Toggl Project mapping.
  """

  import Ecto.Query

  alias Ecto.Changeset
  alias Mittens.Repo
  alias Mittens.Toggl.TogglProject

  def get_project(key) when is_binary(key) do
    TogglProject
    |> where([t], t.key == ^key)
    |> Repo.one()
  end

  def get_project_by_key(key, _) do
    {:error, :too_many_retries}
  end

  def maybe_refresh_projects(%TogglProject{} = project, _, _) do
    project
  end

  def maybe_refresh_projects(nil, key, retries) do
    refresh_projects()

    get_project_by_key(key, retries + 1)
  end

  def refresh_projects() do
    with [token: token, workspace_id: workspace_id] = Application.get_env(:mittens, :toggl),
         headers <- [{"Authorization", "Basic #{base64_token(token)}"}],
         url <-
           "https://api.track.toggl.com/api/v9/workspaces/#{workspace_id}/projects?active=true",
         {:ok, {_, _, body}} <- :httpc.request(:get, {url, headers}, [], []),
         {:ok, results} <- Jason.decode(body) do
      results
      |> Enum.map(&process_toggl_project/1)
      |> Enum.each(&upsert_toggl_project/1)
    end
  end

  def base64_token(token) do
    token
    |> Kernel.<>(":api_token")
    |> Base.encode64()
  end

  defp process_toggl_project(%{"id" => id, "name" => name} = project) do
    [key | _] = String.split(name, "(")
    params = %{description: name, key: key, project_id: to_string(id)}
    TogglProject.changeset(%TogglProject{}, params) |> IO.inspect()
  end

  defp upsert_toggl_project(%Changeset{} = changeset) do
    Repo.insert(changeset,
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: :key
    )
  end
end
