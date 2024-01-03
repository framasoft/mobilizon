defmodule Mobilizon.Service.Workers.RefreshInstances do
  @moduledoc """
  Worker to refresh the instances materialized view and the relay actors
  """

  use Oban.Worker

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Federation.NodeInfo
  alias Mobilizon.Instances
  alias Mobilizon.Instances.{Instance, InstanceActor}
  alias Oban.Job
  require Logger

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Job{}) do
    Instances.refresh()

    Instances.all_domains()
    |> Enum.each(fn %Instance{domain: domain} -> refresh_instance_actor(domain) end)
  end

  @spec refresh_instance_actor(String.t() | nil) ::
          {:ok, Mobilizon.Actors.Actor.t()} | {:error, Ecto.Changeset.t()} | {:error, atom}
  def refresh_instance_actor(nil) do
    {:error, :not_remote_instance}
  end

  def refresh_instance_actor(domain) do
    %Actor{url: url} = Relay.get_actor()
    %URI{host: host} = URI.new!(url)

    if host == domain do
      {:error, :not_remote_instance}
    else
      actor_id =
        case fetch_actor(domain) do
          {:ok, %Actor{id: actor_id}} -> actor_id
          _ -> nil
        end

      with instance_metadata <- fetch_instance_metadata(domain),
           args <- %{
             domain: domain,
             actor_id: actor_id,
             instance_name: get_in(instance_metadata, ["metadata", "nodeName"]),
             instance_description: get_in(instance_metadata, ["metadata", "nodeDescription"]),
             software: get_in(instance_metadata, ["software", "name"]),
             software_version: get_in(instance_metadata, ["software", "version"])
           },
           :ok <- Logger.debug("Ready to save instance actor details #{inspect(args)}"),
           {:ok, %InstanceActor{}} <-
             Instances.create_instance_actor(args) do
        Logger.info("Saved instance actor details for domain #{host}")
      else
        err ->
          Logger.error(inspect(err))
      end
    end
  end

  defp mobilizon(domain), do: "relay@#{domain}"
  defp peertube(domain), do: "peertube@#{domain}"
  defp mastodon(domain), do: "#{domain}@#{domain}"

  defp fetch_actor(domain) do
    case NodeInfo.application_actor(domain) do
      nil -> guess_application_actor(domain)
      url -> ActivityPubActor.get_or_fetch_actor_by_url(url)
    end
  end

  defp fetch_instance_metadata(domain) do
    case NodeInfo.nodeinfo(domain) do
      {:error, _} ->
        %{}

      {:ok, metadata} ->
        metadata
    end
  end

  defp guess_application_actor(domain) do
    Enum.find_value(
      [
        &mobilizon/1,
        &peertube/1,
        &mastodon/1
      ],
      {:error, :no_application_actor_found},
      fn username_pattern ->
        case ActivityPubActor.find_or_make_actor_from_nickname(username_pattern.(domain)) do
          {:ok, %Actor{type: :Application} = actor} -> {:ok, actor}
          {:error, _err} -> false
          {:ok, _actor} -> false
        end
      end
    )
  end
end
