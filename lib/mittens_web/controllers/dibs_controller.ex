defmodule MittensWeb.DibsController do
  @moduledoc false

  @valid_servers ["develop", "staging"]

  use MittensWeb, :controller

  alias Mittens.Dibs
  alias Mittens.Dibs.Dib
  alias Plug.Conn

  @seconds_in_day 8640

  def dibs(%Conn{} = conn, %{"text" => ""} = params) do
    @valid_servers
    |> Enum.map(&"`#{&1}`#{Dibs.print_dib(Dibs.get_dib_by_name(&1))}")
    |> Enum.join("\n")
    |> then(&text(conn, &1))
  end

  def dibs(%Conn{} = conn, %{"text" => text} = params) do
    IO.inspect(params)
    now = DateTime.utc_now()
    [name | days] = String.split(text)

    days =
      case Enum.at(days, 0) do
        day_string when is_binary(day_string) -> String.to_integer(day_string)
        _ -> 1
      end

    case Dibs.get_dib_by_name(name, true) do
      %Dib{expiry: expiry} = dib when expiry > now ->
        text(conn, "#{name}#{Dibs.print_dib(dib)}")

      dib ->
        expiry = end_of_day(days)
        new_params = %{account: Map.get(params, "user_id"), expiry: expiry, name: name}
        Dibs.upsert_dib(dib || %Dib{}, new_params)
        text(conn, "Reserved `#{name}` until #{expiry}!")
    end
  end

  def undibs(%Conn{} = conn, %{"user_id" => account} = params) do
    account
    |> Dibs.get_dibs_by_account()
    |> Enum.map(&Dibs.delete_dib/1)
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(&print_undib/1)
    |> Enum.join("\n")
    |> case do
      "" -> text(conn, "You don't have any servers reserved!")
      servers -> text(conn, servers)
    end
  end

  defp print_undib(%Dib{account: account, name: name} = dib) do
    "Unassigned <@#{account}> from `#{name}`"
  end

  defp end_of_day(days) when is_integer(days) do
    Timex.today()
    |> Date.add(days)
    |> Timex.to_datetime()
  end
end
