defmodule MittensWeb.ZoneController do
  @moduledoc false

  use MittensWeb, :controller

  alias Mittens.{Accounts, Repo, Zones}
  alias Mittens.Accounts.Account

  alias Mittens.Zones.Zone
  alias Plug.Conn

  @header_message """
  *Mission Control Checklist*
  (Please sign off with a :white_check_mark: if your section is good)
  (Please sign off with a :warning: if your section has issues)
  """

  @shuffle_message "*Your new assignments are...*"

  @doc """
  `index/2` will list the zones of responsibility.
  """
  def index(%Conn{} = conn, _) do
    text(conn, "Hi")
  end

  def command(%Conn{} = conn, %{"text" => "run"} = params) do
    channel = get_channel(params)

    zones =
      []
      |> Zones.list_zones()
      |> Enum.map(&Zones.print_zone/1)
      |> then(&[@header_message | &1])

    Task.async(fn -> Enum.each(zones, &Slack.Web.Chat.post_message(channel, &1)) end)
    text(conn, "")
  end

  def command(%Conn{} = conn, %{"text" => "coinflip"} = params) do
    channel = get_channel(params)

    coinflip = Enum.random(["Heads", "Tails"])

    messages = ["Flipping coin...", "The coin landed on #{coinflip}!"]

    Task.async(fn -> Enum.each(messages, &Slack.Web.Chat.post_message(channel, &1)) end)
    text(conn, "")
  end

  def command(%Conn{} = conn, %{"text" => "shuffle"} = params) do
    channel = get_channel(params)

    Zones.shuffle_zones(false)

    zones =
      []
      |> Zones.list_zones()
      |> Enum.map(&Zones.print_zone/1)
      |> then(&[@shuffle_message | &1])

    Task.async(fn -> Enum.each(zones, &Slack.Web.Chat.post_message(channel, &1)) end)
    text(conn, "")
  end

  def command(%Conn{} = conn, %{"text" => text}) do
    text(conn, parse_command_text(text))
  end

  defp parse_command_text("add " <> zone_data) do
    {zone, slug} = get_slug(zone_data)

    slug
    |> Zones.get_zone_by_slug()
    |> case do
      %Zone{} ->
        "Zone \"#{zone}\" already exists"

      _ ->
        Zones.upsert_zone(%Zone{}, %{name: zone, slug: slug})
        "Added zone \"#{zone}\" (#{slug})"
    end
  end

  defp parse_command_text("assign " <> params) do
    with regex <- ~r/\<\@(.*?)\|(.*?)\> (.*)/,
         [_, id, name, slug] <- Regex.run(regex, params),
         %Zone{} = zone <- Zones.get_zone_by_slug(slug) || :zone_not_found,
         zone <- Repo.preload(zone, :accounts) do
      {:ok, %{account: account}} =
        case Accounts.get_account_by_external_id(id) do
          %Account{} = account -> {:ok, %{account: account}}
          _ -> Accounts.upsert_account(%Account{}, %{external_id: id, name: name})
        end

      Zones.assign_account(zone, account)

      "Assigned <@#{id}> to \"#{zone.name}\""
    else
      :zone_not_found -> "Zone not found"
      _ -> "Invalid syntax"
    end
  end

  defp parse_command_text("unassign " <> params) do
    with regex <- ~r/\<\@(.*?)\|(.*?)\> (.*)/,
         [_, id, _, slug] <- Regex.run(regex, params),
         %Zone{} = zone <- Zones.get_zone_by_slug(slug) || :zone_not_found,
         %{accounts: accounts} = zone <- Repo.preload(zone, :accounts),
         %Account{} = account <- Enum.find(accounts, &(&1.external_id == id)) do
      Zones.unassign_account(zone, account)

      "Unassigned <@#{id}> from \"#{zone.name}\""
    else
      :zone_not_found -> "Zone not found"
      nil -> "Account not associated with zone"
      _ -> "Invalid syntax"
    end
  end

  defp parse_command_text("list assigned" <> _) do
    []
    |> Zones.list_zones()
    |> Enum.map(&Zones.print_zone/1)
    |> then(&["*Zones:*" | &1])
    |> Enum.join("\n")
  end

  defp parse_command_text("list" <> _) do
    []
    |> Zones.list_zones()
    |> Enum.map(&"\"#{&1.name}\" (`#{&1.slug}`)")
    |> then(&["*Zones:*" | &1])
    |> Enum.join("\n")
  end

  defp get_slug(zone_data) do
    case Regex.run(~r/"(.*?)" (.*)/, zone_data) do
      [_, name, slug] -> {name, slug}
      _ -> {zone_data, Recase.to_kebab(zone_data)}
    end
  end

  defp get_channel(%{"channel_name" => "directmessage", "user_id" => user}), do: user
  defp get_channel(%{"channel_name" => name}), do: name
end
