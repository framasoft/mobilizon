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

    with author_id <- get_author(new_member, options),
         object_id <- if(subject == "member_removed", do: nil, else: to_string(member_id)) do
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
  end

  def insert_activity(_, _), do: {:ok, nil}

  @spec get_author(Member.t(), Member.t() | nil) :: String.t() | integer()
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

    moderator = Keyword.get(options, :moderator)
    old_member = Keyword.get(options, :old_member)

    subject_params = %{
      member_role: String.upcase(to_string(role))
    }

    subject_params =
      if(is_nil(actor),
        do: subject_params,
        else:
          Map.put(
            subject_params,
            :member_preferred_username,
            Actor.preferred_username_and_domain(actor)
          )
      )

    subject_params =
      if(is_nil(old_member),
        do: subject_params,
        else: Map.put(subject_params, :old_role, String.upcase(to_string(old_member.role)))
      )

    if is_nil(moderator),
      do: subject_params,
      else:
        Map.put(
          subject_params,
          :moderator_preferred_username,
          Actor.preferred_username_and_domain(moderator)
        )
  end
end
