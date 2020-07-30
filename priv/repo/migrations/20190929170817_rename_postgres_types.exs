defmodule Mobilizon.Storage.Repo.Migrations.RenamePostgresTypes do
  use Ecto.Migration
  alias Mobilizon.Actors.{ActorVisibility, MemberRole}

  alias Mobilizon.Discussions.CommentVisibility

  alias Mobilizon.Events.{
    JoinOptions,
    EventStatus,
    EventVisibility,
    ParticipantRole
  }

  alias Mobilizon.Users.UserRole

  @types %{
    "actor_visibility_type" => ActorVisibility.type(),
    "comment_visibility_type" => CommentVisibility.type(),
    "event_join_options_type" => JoinOptions.type(),
    "event_status_type" => EventStatus.type(),
    "event_visibility_type" => EventVisibility.type(),
    "member_role_type" => MemberRole.type(),
    "participant_role_type" => ParticipantRole.type(),
    "user_role_type" => UserRole.type()
  }

  def up do
    Enum.each(@types, fn {k, v} -> rename_type(k, v) end)
  end

  def down do
    Enum.each(@types, fn {k, v} -> rename_type(v, k) end)
  end

  defp rename_type(old_type_name, new_type_name) do
    with %Postgrex.Result{columns: ["exists"], rows: [[true]]} <-
           Ecto.Adapters.SQL.query!(
             Mobilizon.Storage.Repo,
             "select exists (select 1 from pg_type where typname = '#{
               old_type_name |> remove_schema
             }' and typnamespace = (select oid from pg_namespace where nspname = 'public'))"
           ) do
      Ecto.Migration.execute(
        "ALTER TYPE #{old_type_name |> remove_schema} RENAME TO #{new_type_name |> remove_schema}"
      )
    end
  end

  # We don't want the schema: public.actor_visibility => actor_visibility
  def remove_schema(schema) when is_atom(schema), do: remove_schema(to_string(schema))
  def remove_schema("public." <> schema), do: schema
  def remove_schema(schema), do: schema
end
