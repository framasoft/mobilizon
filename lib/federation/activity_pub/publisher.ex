defmodule Mobilizon.Federation.ActivityPub.Publisher do
  @moduledoc """
  Handle publishing activities
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Federation.ActivityPub.{Activity, Federator, Relay, Transmogrifier, Visibility}
  alias Mobilizon.Federation.HTTPSignatures.Signature
  alias Mobilizon.Service.HTTP.ActivityPub, as: ActivityPubClient
  require Logger

  import Mobilizon.Federation.ActivityPub.Utils,
    only: [remote_actors: 1, create_full_domain_string: 1]

  @doc """
  Publish an activity to all appropriated audiences inboxes
  """
  # credo:disable-for-lines:47
  @spec publish(Actor.t(), Activity.t()) :: :ok
  def publish(actor, %Activity{recipients: recipients} = activity) do
    Logger.debug("Publishing an activity")
    Logger.debug(inspect(activity, pretty: true))

    public = Visibility.public?(activity)
    Logger.debug("is public ? #{public}")

    if public && create_activity?(activity) && Config.get([:instance, :allow_relay]) do
      Logger.info(fn -> "Relaying #{activity.data["id"]} out" end)

      Relay.publish(activity)
    end

    recipients =
      if public && Config.get([:instance, :allow_relay]) do
        followers_url = Relay.get_actor().followers_url

        Logger.debug(
          "Public activity, so adding relay followers URL to recipients: #{inspect(followers_url)}"
        )

        recipients ++ [followers_url]
      else
        recipients
      end

    recipients = Enum.uniq(recipients)

    {recipients, followers} = convert_followers_in_recipients(recipients)

    Logger.debug("Found the following followers: #{inspect(Enum.map(followers, & &1.url))}")

    {recipients, members} = convert_members_in_recipients(recipients)

    Logger.debug("Found the following followers: #{inspect(Enum.map(members, & &1.url))}")

    remote_inboxes =
      (remote_actors(recipients) ++ followers ++ members)
      |> Enum.map(fn actor -> actor.shared_inbox_url || actor.inbox_url end)
      |> Enum.uniq()

    {:ok, data} = Transmogrifier.prepare_outgoing(activity.data)
    json = Jason.encode!(data)
    Logger.debug(fn -> "Remote inboxes are : #{inspect(remote_inboxes)}" end)

    Enum.each(remote_inboxes, fn inbox ->
      Federator.enqueue(:publish_single_ap, %{
        inbox: inbox,
        json: json,
        actor: actor,
        id: activity.data["id"]
      })
    end)
  end

  @doc """
  Publish an activity to a specific inbox
  """
  @spec publish_one(%{inbox: String.t(), json: String.t(), actor: Actor.t(), id: String.t()}) ::
          Tesla.Env.result()
  def publish_one(%{inbox: inbox, json: json, actor: actor, id: id}) do
    Logger.info("Federating #{id} to #{inbox}")
    %URI{path: path} = uri = URI.new!(inbox)

    digest = Signature.build_digest(json)
    date = Signature.generate_date_header()

    # request_target = Signature.generate_request_target("POST", path)

    signature =
      Signature.sign(actor, %{
        "(request-target)": "post #{path}",
        host: create_full_domain_string(uri),
        "content-length": byte_size(json),
        digest: digest,
        date: date
      })

    headers = [
      {"Content-Type", "application/activity+json"},
      {"signature", signature},
      {"digest", digest},
      {"date", date}
    ]

    client = ActivityPubClient.client(headers: headers)

    ActivityPubClient.post(client, inbox, json)
  end

  @spec convert_followers_in_recipients(list(String.t())) :: {list(String.t()), list(String.t())}
  defp convert_followers_in_recipients(recipients) do
    Enum.reduce(recipients, {recipients, []}, fn recipient, {recipients, follower_actors} = acc ->
      if is_nil(recipient) do
        acc
      else
        case Actors.get_actor_by_followers_url(recipient) do
          %Actor{} = group ->
            {Enum.filter(recipients, fn recipient -> recipient != group.followers_url end),
             follower_actors ++ Actors.list_external_followers_for_actor(group)}

          nil ->
            acc
        end
      end
    end)
  end

  @spec create_activity?(Activity.t()) :: boolean
  defp create_activity?(%Activity{data: %{"type" => "Create"}}), do: true
  defp create_activity?(_), do: false

  @spec convert_members_in_recipients(list(String.t())) :: {list(String.t()), list(Actor.t())}
  defp convert_members_in_recipients(recipients) do
    Enum.reduce(recipients, {recipients, []}, fn recipient, {recipients, member_actors} = acc ->
      if is_nil(recipient) do
        acc
      else
        case Actors.get_group_by_members_url(recipient) do
          # If the group is local just add external members
          %Actor{domain: domain} = group when is_nil(domain) ->
            {Enum.filter(recipients, fn recipient -> recipient != group.members_url end),
             member_actors ++ Actors.list_external_actors_members_for_group(group)}

          # If it's remote add the remote group actor as well
          %Actor{} = group ->
            {Enum.filter(recipients, fn recipient -> recipient != group.members_url end),
             member_actors ++ Actors.list_external_actors_members_for_group(group) ++ [group]}

          _ ->
            acc
        end
      end
    end)
  end
end
