defmodule MittensWeb.DibsController do
  @moduledoc false

  @valid_servers ["develop", "staging", "test"]

  use MittensWeb, :controller

  alias Mittens.Dibs
  alias Mittens.Dibs.Dib
  alias Plug.Conn

  def dibs(%Conn{} = conn, %{"text" => ""}) do
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

    if name in @valid_servers do
      dib = Dibs.get_dib_by_name(name, true)

      with %Dib{expiry: expiry} <- dib,
           :gt <- DateTime.compare(expiry, now) do
        text(conn, "#{name}#{Dibs.print_dib(dib)}")
      else
        _ ->
          expiry = end_of_day(days)
          new_params = %{account: Map.get(params, "user_id"), expiry: expiry, name: name}
          Dibs.upsert_dib(dib || %Dib{}, new_params)

          text(
            conn,
            "Reserved `#{name}` until midnight on #{Timex.format!(expiry, "{Mfull} {D}")}#{past_message(days)}"
          )
      end
    else
      text(conn, "`#{name}`? `#{name}` is not a real server. Quit playin'!")
    end
  end

  def undibs(%Conn{} = conn, %{"user_id" => account}) do
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

  defp print_undib(%Dib{account: account, name: name}) do
    "Unassigned <@#{account}> from `#{name}`"
  end

  defp end_of_day(days) when is_integer(days) do
    Timex.today()
    |> Date.add(days)
    |> Timex.to_datetime()
  end

  defp past_message(days) when is_integer(days) and days < 1 do
    "... which is in the past. But hey, you're the boss, boss. :shrug:"
  end

  defp past_message(_) do
    ""
  end
end
