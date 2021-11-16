defmodule Mobilizon.Federation.ActivityPub.Types.Actors do
  @moduledoc false
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Follower, Member, MemberRole}
  alias Mobilizon.Federation.ActivityPub.{Actions, Audience, Permission, Relay}
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream
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
  @spec create(map(), map()) ::
          {:ok, Actor.t(), ActivityStream.t()} | {:error, Ecto.Changeset.t()}
  def create(args, additional) do
    args = prepare_args_for_actor(args)

    case Actors.create_actor(args) do
      {:ok, %Actor{} = actor} ->
        GroupActivity.insert_activity(actor,
          subject: "group_created",
          actor_id: args.creator_actor_id
        )

        actor_as_data = Convertible.model_to_as(actor)
        audience = %{"to" => ["https://www.w3.org/ns/activitystreams#Public"], "cc" => []}
        create_data = make_create_data(actor_as_data, Map.merge(audience, additional))
        {:ok, actor, create_data}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @impl Entity
  @spec update(Actor.t(), map, map) ::
          {:ok, Actor.t(), ActivityStream.t()} | {:error, Ecto.Changeset.t()}
  def update(%Actor{} = old_actor, args, additional) do
    updater_actor = Map.get(args, :updater_actor) || Map.get(additional, :updater_actor)

    case Actors.update_actor(old_actor, args) do
      {:ok, %Actor{} = new_actor} ->
        GroupActivity.insert_activity(new_actor,
          subject: "group_updated",
          old_group: old_actor,
          updater_actor: updater_actor
        )

        actor_as_data = Convertible.model_to_as(new_actor)
        Cachex.del(:activity_pub, "actor_#{new_actor.preferred_username}")
        audience = Audience.get_audience(new_actor)

        additional = Map.merge(additional, %{"actor" => (updater_actor || old_actor).url})

        update_data = make_update_data(actor_as_data, Map.merge(audience, additional))
        {:ok, new_actor, update_data}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @public_ap "https://www.w3.org/ns/activitystreams#Public"

  @impl Entity
  @spec delete(Actor.t(), Actor.t(), boolean, map) ::
          {:ok, ActivityStream.t(), Actor.t(), Actor.t()} | {:error, Ecto.Changeset.t()}
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
      "object" => %{
        "type" => "Tombstone",
        "formerType" => to_string(type),
        "deleted" => DateTime.utc_now(),
        "id" => target_actor_url
      },
      "id" => target_actor_url <> "/delete",
      "to" => to,
      "cc" => cc
    }

    suspension = Map.get(additionnal, :suspension, false)

    case Actors.delete_actor(target_actor,
           # We completely delete the actor if the actor is remote
           reserve_username: is_nil(domain),
           suspension: suspension,
           author_id: author_id
         ) do
      {:ok, %Oban.Job{}} ->
        {:ok, activity_data, actor, target_actor}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @spec actor(Actor.t()) :: Actor.t() | nil
  def actor(%Actor{} = actor), do: actor

  @spec group_actor(Actor.t()) :: Actor.t() | nil
  def group_actor(%Actor{} = actor), do: actor

  @spec permissions(Actor.t()) :: Permission.t()
  def permissions(%Actor{} = _group) do
    %Permission{
      access: :member,
      create: nil,
      update: :administrator,
      delete: :administrator
    }
  end

  @spec join(Actor.t(), Actor.t(), boolean(), map()) :: {:ok, ActivityStreams.t(), Member.t()}
  def join(%Actor{type: :Group} = group, %Actor{} = actor, _local, additional) do
    role =
      additional
      |> Map.get(:metadata, %{})
      |> Map.get(:role, Mobilizon.Actors.get_default_member_role(group))

    case Mobilizon.Actors.create_member(%{
           role: role,
           parent_id: group.id,
           actor_id: actor.id,
           url: Map.get(additional, :url),
           metadata:
             additional
             |> Map.get(:metadata, %{})
             |> Map.update(:message, nil, &String.trim(HTML.strip_tags(&1)))
         }) do
      {:ok, %Member{} = member} ->
        subject =
          case Mobilizon.Actors.get_default_member_role(group) do
            :not_approved -> "member_request"
            :member -> "member_joined"
          end

        Mobilizon.Service.Activity.Member.insert_activity(member, subject: subject)

        Absinthe.Subscription.publish(Endpoint, actor,
          group_membership_changed: [Actor.preferred_username_and_domain(group), actor.id]
        )

        join_data = %{
          "type" => "Join",
          "id" => member.url,
          "actor" => actor.url,
          "object" => group.url
        }

        audience = Audience.get_audience(member)

        approve_if_default_role_is_member(
          group,
          actor,
          Map.merge(join_data, audience),
          member,
          role
        )

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @spec follow(Actor.t(), Actor.t(), boolean, map) ::
          {:accept, any}
          | {:ok, ActivityStreams.t(), Follower.t()}
          | {:error,
             :person_no_follow | :already_following | :followed_suspended | Ecto.Changeset.t()}
  def follow(%Actor{} = follower_actor, %Actor{type: type} = followed, _local, additional)
      when type != :Person do
    case Mobilizon.Actors.follow(followed, follower_actor, additional["activity_id"], false) do
      {:ok, %Follower{} = follower} ->
        FollowMailer.send_notification_to_admins(follower)
        follower_as_data = Convertible.model_to_as(follower)
        approve_if_manually_approves_followers(follower, follower_as_data)

      {:error, error} ->
        {:error, error}
    end
  end

  # "Only group and instances can be followed"
  def follow(_, _, _, _), do: {:error, :person_no_follow}

  @spec prepare_args_for_actor(map) :: map
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
  @spec approve_if_default_role_is_member(
          Actor.t(),
          Actor.t(),
          ActivityStreams.t(),
          Member.t(),
          MemberRole.t()
        ) ::
          {:ok, ActivityStreams.t(), Member.t()}
  defp approve_if_default_role_is_member(
         %Actor{type: :Group} = group,
         %Actor{} = actor,
         activity_data,
         %Member{} = member,
         role
       ) do
    if is_nil(group.domain) && !is_nil(actor.domain) do
      cond do
        Mobilizon.Actors.get_default_member_role(group) == :member &&
            role == :member ->
          {:accept,
           Actions.Accept.accept(
             :join,
             member,
             true,
             %{"actor" => group.url}
           )}

        Mobilizon.Actors.get_default_member_role(group) == :not_approved &&
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

  @spec approve_if_manually_approves_followers(
          follower :: Follower.t(),
          follow_as_data :: ActivityStreams.t()
        ) ::
          {:accept, any} | {:ok, ActivityStreams.t(), Follower.t()}
  defp approve_if_manually_approves_followers(
         %Follower{} = follower,
         follow_as_data
       ) do
    %Actor{id: relay_id} = Relay.get_actor()

    unless follower.target_actor.manually_approves_followers or
             follower.target_actor.id == relay_id do
      require Logger
      Logger.debug("Target doesn't manually approves followers, we can accept right away")

      {:accept,
       Actions.Accept.accept(
         :follow,
         follower,
         true,
         %{"actor" => follower.actor.url}
       )}
    end

    {:ok, follow_as_data, follower}
  end
end
