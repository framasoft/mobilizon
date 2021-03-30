defmodule Mobilizon.Federation.ActivityPub.Types.Actors do
  @moduledoc false
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Follower, Member}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.{Audience, Relay}
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.GraphQL.API.Utils, as: APIUtils
  alias Mobilizon.Service.Activity.Group, as: GroupActivity
  alias Mobilizon.Service.Formatter.HTML
  alias Mobilizon.Service.Notifications.Scheduler
  alias Mobilizon.Web.Email.Follow, as: FollowMailer
  alias Mobilizon.Web.Endpoint
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_create_data: 2, make_update_data: 2]

  @behaviour Entity

  @impl Entity
  @spec create(map(), map()) :: {:ok, map()}
  def create(args, additional) do
    with args <- prepare_args_for_actor(args),
         {:ok, %Actor{} = actor} <- Actors.create_actor(args),
         {:ok, _} <-
           GroupActivity.insert_activity(actor,
             subject: "group_created",
             actor_id: args.creator_actor_id
           ),
         actor_as_data <- Convertible.model_to_as(actor),
         audience <- %{"to" => ["https://www.w3.org/ns/activitystreams#Public"], "cc" => []},
         create_data <-
           make_create_data(actor_as_data, Map.merge(audience, additional)) do
      {:ok, actor, create_data}
    end
  end

  @impl Entity
  @spec update(Actor.t(), map, map) :: {:ok, Actor.t(), Activity.t()} | any
  def update(%Actor{} = old_actor, args, additional) do
    with {:ok, %Actor{} = new_actor} <- Actors.update_actor(old_actor, args),
         {:ok, _} <-
           GroupActivity.insert_activity(new_actor,
             subject: "group_updated",
             old_group: old_actor,
             updater_actor: Map.get(args, :updater_actor)
           ),
         actor_as_data <- Convertible.model_to_as(new_actor),
         {:ok, true} <- Cachex.del(:activity_pub, "actor_#{new_actor.preferred_username}"),
         audience <-
           Audience.calculate_to_and_cc_from_mentions(new_actor),
         additional <- Map.merge(additional, %{"actor" => old_actor.url}),
         update_data <- make_update_data(actor_as_data, Map.merge(audience, additional)) do
      {:ok, new_actor, update_data}
    end
  end

  @public_ap "https://www.w3.org/ns/activitystreams#Public"

  @impl Entity
  def delete(
        %Actor{
          followers_url: followers_url,
          members_url: members_url,
          url: target_actor_url,
          type: type,
          domain: domain
        } = target_actor,
        %Actor{url: actor_url, id: author_id} = actor,
        _local,
        additionnal
      ) do
    to = [@public_ap, followers_url]

    {to, cc} =
      if type == :Group do
        {to ++ [members_url], [target_actor_url]}
      else
        {to, []}
      end

    activity_data = %{
      "type" => "Delete",
      "actor" => actor_url,
      "object" => Convertible.model_to_as(target_actor),
      "id" => target_actor_url <> "/delete",
      "to" => to,
      "cc" => cc
    }

    suspension = Map.get(additionnal, :suspension, false)

    with {:ok, %Oban.Job{}} <-
           Actors.delete_actor(target_actor,
             # We completely delete the actor if the actor is remote
             reserve_username: is_nil(domain),
             suspension: suspension,
             author_id: author_id
           ) do
      {:ok, activity_data, actor, target_actor}
    end
  end

  def actor(%Actor{} = actor), do: actor

  def group_actor(%Actor{} = actor), do: actor

  def role_needed_to_update(%Actor{} = _group), do: :administrator
  def role_needed_to_delete(%Actor{} = _group), do: :administrator

  @spec join(Actor.t(), Actor.t(), boolean(), map()) :: {:ok, map(), Member.t()}
  def join(%Actor{type: :Group} = group, %Actor{} = actor, _local, additional) do
    with role <-
           additional
           |> Map.get(:metadata, %{})
           |> Map.get(:role, Mobilizon.Actors.get_default_member_role(group)),
         {:ok, %Member{} = member} <-
           Mobilizon.Actors.create_member(%{
             role: role,
             parent_id: group.id,
             actor_id: actor.id,
             url: Map.get(additional, :url),
             metadata:
               additional
               |> Map.get(:metadata, %{})
               |> Map.update(:message, nil, &String.trim(HTML.strip_tags(&1)))
           }),
         {:ok, _} <-
           Mobilizon.Service.Activity.Member.insert_activity(member, subject: "member_joined"),
         Absinthe.Subscription.publish(Endpoint, actor,
           group_membership_changed: [Actor.preferred_username_and_domain(group), actor.id]
         ),
         join_data <- %{
           "type" => "Join",
           "id" => member.url,
           "actor" => actor.url,
           "object" => group.url
         },
         audience <-
           Audience.calculate_to_and_cc_from_mentions(member) do
      approve_if_default_role_is_member(
        group,
        actor,
        Map.merge(join_data, audience),
        member,
        role
      )
    end
  end

  def follow(%Actor{} = follower_actor, %Actor{type: type} = followed, _local, additional)
      when type != :Person do
    with {:ok, %Follower{} = follower} <-
           Mobilizon.Actors.follow(followed, follower_actor, additional["activity_id"], false),
         :ok <- FollowMailer.send_notification_to_admins(follower),
         follower_as_data <- Convertible.model_to_as(follower) do
      approve_if_manually_approves_followers(follower, follower_as_data)
    end
  end

  def follow(_, _, _, _), do: {:error, :no_person, "Only group and instances can be followed"}

  defp prepare_args_for_actor(args) do
    args
    |> maybe_sanitize_username()
    |> maybe_sanitize_summary()
  end

  @spec maybe_sanitize_username(map()) :: map()
  defp maybe_sanitize_username(%{preferred_username: preferred_username} = args) do
    Map.put(args, :preferred_username, preferred_username |> HTML.strip_tags() |> String.trim())
  end

  defp maybe_sanitize_username(args), do: args

  @spec maybe_sanitize_summary(map()) :: map()
  defp maybe_sanitize_summary(%{summary: summary} = args) do
    {summary, _mentions, _tags} =
      summary
      |> String.trim()
      |> APIUtils.make_content_html([], "text/html")

    Map.put(args, :summary, summary)
  end

  defp maybe_sanitize_summary(args), do: args

  # Set the participant to approved if the default role for new participants is :participant
  @spec approve_if_default_role_is_member(Actor.t(), Actor.t(), map(), Member.t(), atom()) ::
          {:ok, map(), Member.t()}
  defp approve_if_default_role_is_member(
         %Actor{type: :Group} = group,
         %Actor{} = actor,
         activity_data,
         %Member{} = member,
         role
       ) do
    if is_nil(group.domain) && !is_nil(actor.domain) do
      cond do
        Mobilizon.Actors.get_default_member_role(group) === :member &&
            role == :member ->
          {:accept,
           ActivityPub.accept(
             :join,
             member,
             true,
             %{"actor" => group.url}
           )}

        Mobilizon.Actors.get_default_member_role(group) === :not_approved &&
            role == :not_approved ->
          Scheduler.pending_membership_notification(group)
          {:ok, activity_data, member}

        true ->
          {:ok, activity_data, member}
      end
    else
      {:ok, activity_data, member}
    end
  end

  defp approve_if_manually_approves_followers(
         %Follower{} = follower,
         follow_as_data
       ) do
    %Actor{id: relay_id} = Relay.get_actor()

    unless follower.target_actor.manually_approves_followers or
             follower.target_actor.id == relay_id do
      {:accept,
       ActivityPub.accept(
         :follow,
         follower,
         true,
         %{"actor" => follower.actor.url}
       )}
    end

    {:ok, follow_as_data, follower}
  end
end
