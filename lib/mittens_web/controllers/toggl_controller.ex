defmodule MittensWeb.TogglController do
  @moduledoc false

  use MittensWeb, :controller

  alias Mittens.Toggl
  alias Mittens.Toggl.TogglProject
  alias Plug.Conn


  def show(%Conn{} = conn, %{"key" => key}) do
    case Toggl.get_project(key) do
      %TogglProject{project_id: id} ->
      text(conn, id)
      _ ->
        conn
        |> put_status(:not_found)
        |> text("")
    end

    text(conn, "key")
  end

  def refresh(%Conn{} = conn, _) do
    Toggl.refresh_projects()

    text(conn, "OK")
  end
end
