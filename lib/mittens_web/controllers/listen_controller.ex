defmodule MittensWeb.ListenController do
  @moduledoc false

  use MittensWeb, :controller

  alias Mittens.Zones
  alias Plug.Conn

  @bot_username "HRP Release"
  @header_message """
  *Mission Control Checklist*
  (Please sign off with a :white_check_mark: if your section is good)
  (Please sign off with a :warning: if your section has issues)
  """
  @hotfix_message "Hotfix release detected! Mission Control message: **CANCELLED**"

  @doc """
  `listen/2` listens for messages matching the parameters
  to auto-run the mission control checklist.
  """
  def listen(%Conn{} = conn, %{"challenge" => challenge} = params) do
    IO.inspect(params)
    text(conn, challenge)
  end

  def listen(%Conn{} = conn, %{
        "event" => %{"channel" => channel, "username" => @bot_username, "text" => text}
      }) do
    if Regex.match?(~r/\d\.\d+\.0/, text) do
      zones =
        []
        |> Zones.list_zones()
        |> Enum.map(&Zones.print_zone/1)
        |> then(&[@header_message | &1])

      Task.async(fn -> Enum.each(zones, &Slack.Web.Chat.post_message(channel, &1)) end)
      text(conn, "")
    else
      Task.async(fn -> Slack.Web.Chat.post_message(channel, @hotfix_message) end)
      text(conn, "")
    end
  end

  def listen(%Conn{} = conn, %{} = params) do
    IO.inspect(params)
    text(conn, "")
  end
end
