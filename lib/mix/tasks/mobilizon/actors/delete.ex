defmodule Mix.Tasks.Mobilizon.Actors.Delete do
  @moduledoc """
  Task to delete an actor
  """
  use Mix.Task
  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActorSuspension
  alias Mobilizon.Users.User
  import Mix.Tasks.Mobilizon.Common

  @shortdoc "Deletes a Mobilizon person or a group"

  @impl Mix.Task
  def run([federated_username | rest]) do
    {options, [], []} =
      OptionParser.parse(
        rest,
        strict: [
          assume_yes: :boolean,
          keep_username: :boolean
        ],
        aliases: [
          y: :assume_yes,
          k: :keep_username
        ]
      )

    assume_yes? = Keyword.get(options, :assume_yes, false)
    keep_username? = Keyword.get(options, :keep_username, false)

    start_mobilizon()

    # To make sure we can delete actors created by mistake with "@" in their username
    case Actors.get_local_actor_by_name(federated_username) ||
           Actors.get_actor_by_name(federated_username) do
      %Actor{preferred_username: username, domain: nil} when username in ["relay", "anonymous"] ->
        shell_error("This actor can't be deleted.")

      %Actor{} = actor ->
        if check_everything(actor, assume_yes?) do
          ActorSuspension.suspend_actor(actor,
            reserve_username: keep_username?,
            suspension: false
          )

          display_name = Actor.display_name_and_username(actor)

          shell_info("""
          The actor #{display_name} has been deleted
          """)
        else
          shell_error("Actor has not been deleted.")
        end

      nil ->
        shell_error("No actor found with this username")
    end
  end

  def run(_) do
    shell_error(
      "mobilizon.actors.delete requires an username or a federated username as argument"
    )
  end

  @spec check_everything(Actor.t(), boolean()) :: boolean()
  defp check_everything(%Actor{} = actor, assume_yes?) do
    display_name = Actor.display_name_and_username(actor)

    (assume_yes? or
       shell_yes?(
         "All content by this profile or group will be deleted. Continue with deleting #{display_name}?"
       )) and
      check_actor(actor, assume_yes?)
  end

  @spec check_actor(Actor.t(), boolean()) :: boolean()
  defp check_actor(%Actor{type: :Group} = group, assume_yes?) do
    display_name = Actor.display_name_and_username(group)
    nb_members = Actors.count_members_for_group(group)
    nb_followers = Actors.count_followers_for_actor(group)

    if nb_followers + nb_members > 0 do
      shell_info("Group members will be notified of the group deletion.")

      assume_yes? or
        shell_yes?(
          "Group #{display_name} has #{nb_members} members and #{nb_followers} followers. Continue deleting?"
        )
    else
      true
    end
  end

  defp check_actor(%Actor{type: :Person, domain: nil, user_id: user_id} = profile, assume_yes?)
       when not is_nil(user_id) do
    %User{actors: actors, email: email} = Users.get_user_with_actors!(profile.user_id)

    if length(actors) == 1 do
      assume_yes? or
        shell_yes?(
          "This profile is the only one user #{email} has. Mobilizon will invite the user to create a new profile on their next login. If you want to remove the whole user account, use the `mobilizon.users.delete` command. Continue deleting?"
        )
    else
      true
    end
  end

  defp check_actor(%Actor{} = _actor, assume_yes?), do: assume_yes?
end
