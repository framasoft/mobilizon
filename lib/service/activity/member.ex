defmodule Mobilizon.Service.Activity.Member do
  @moduledoc """
  Insert a member activity
  """
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Service.Activity
  alias Mobilizon.Service.Workers.ActivityBuilder

  @behaviour Activity

  @impl Activity
  def insert_activity(member, options \\ [])

  def insert_activity(
        %Member{parent_id: parent_id, id: member_id} = new_member,
        options
      ) do
    subject = Keyword.get(options, :subject)

    author_id = get_author(new_member, options)
    object_id = if(subject == "member_removed", do: nil, else: to_string(member_id))

    ActivityBuilder.enqueue(:build_activity, %{
      "type" => "member",
      "subject" => subject,
      "subject_params" => get_subject_params(new_member, options),
      "group_id" => parent_id,
      "author_id" => author_id,
      "object_type" => "member",
      "object_id" => object_id,
      "inserted_at" => DateTime.utc_now()
    })
  end

  def insert_activity(_, _), do: {:ok, nil}

  @impl Activity
  def get_object(member_id) do
    Actors.get_member(member_id)
  end

  @spec get_author(Member.t(), Keyword.t()) :: integer()
  defp get_author(%Member{actor_id: actor_id}, options) do
    moderator = Keyword.get(options, :moderator)

    if is_nil(moderator) do
      actor_id
    else
      moderator.id
    end
  end

  @spec get_subject_params(Member.t(), Keyword.t()) :: map()
  defp get_subject_params(%Member{actor: actor, role: role, id: member_id}, options) do
    # We may need to preload the member to make sure the actor exists
    actor =
      case actor do
        %Actor{} = actor ->
          actor

        _ ->
          case Actors.get_member(member_id) do
            %Member{actor: actor} -> actor
            _ -> nil
          end
      end

    %{
      member_role: String.upcase(to_string(role))
    }
    |> maybe_add_actor(actor)
    |> maybe_add_old_member(Keyword.get(options, :old_member))
    |> maybe_add_moderator(Keyword.get(options, :moderator))
  end

  @spec maybe_add_actor(map(), Actor.t() | nil) :: map()
  defp maybe_add_actor(subject_params, nil), do: subject_params

  defp maybe_add_actor(subject_params, %Actor{} = actor) do
    subject_params
    |> Map.put(
      :member_actor_federated_username,
      Actor.preferred_username_and_domain(actor)
    )
    |> Map.put(:member_actor_name, actor.name)
  end

  @spec maybe_add_old_member(map(), Member.t() | nil) :: map()
  defp maybe_add_old_member(subject_params, nil), do: subject_params

  defp maybe_add_old_member(subject_params, old_member) do
    Map.put(subject_params, :old_role, String.upcase(to_string(old_member.role)))
  end

  @spec maybe_add_moderator(map(), Actor.t() | nil) :: map()
  defp maybe_add_moderator(subject_params, nil), do: subject_params

  defp maybe_add_moderator(subject_params, moderator) do
    Map.put(
      subject_params,
      :moderator_preferred_username,
      Actor.preferred_username_and_domain(moderator)
    )
  end
end
