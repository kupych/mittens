defmodule Mittens.Repo do
  use Ecto.Repo,
    otp_app: :mittens,
    adapter: Ecto.Adapters.Postgres
end
