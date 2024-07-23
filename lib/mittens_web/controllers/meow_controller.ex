defmodule MittensWeb.MeowController do
  use MittensWeb, :controller

  def index(conn, _params) do
    conn
    |> put_status(:ok)
    |> text("Meow")
  end
end
