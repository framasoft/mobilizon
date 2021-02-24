defmodule Mobilizon.Service.Activity.Resource do
  @moduledoc """
  Insert an resource activity
  """
  alias Mobilizon.Actors
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Service.Activity
  alias Mobilizon.Service.Workers.ActivityBuilder

  @behaviour Activity

  @impl Activity
  def insert_activity(resource, options \\ [])

  def insert_activity(
        %Resource{actor_id: actor_id, creator_id: creator_id} = resource,
        options
      )
      when not is_nil(actor_id) do
    actor = Actors.get_actor(creator_id)
    group = Actors.get_actor(actor_id)
    subject = Keyword.fetch!(options, :subject)
    old_resource = Keyword.get(options, :old_resource)

    ActivityBuilder.enqueue(:build_activity, %{
      "type" => "resource",
      "subject" => subject,
      "subject_params" => subject_params(resource, subject, old_resource),
      "group_id" => group.id,
      "author_id" => actor.id,
      "object_type" => "resource",
      "object_id" => if(subject != "resource_deleted", do: to_string(resource.id), else: nil),
      "inserted_at" => DateTime.utc_now()
    })
  end

  @impl Activity
  def insert_activity(_, _), do: {:ok, nil}

  @spec subject_params(Resource.t(), String.t() | nil, Resource.t() | nil) :: map()
  defp subject_params(%Resource{} = resource, "resource_renamed", old_resource) do
    resource
    |> subject_params(nil, nil)
    |> Map.put(:old_resource_title, old_resource.title)
  end

  defp subject_params(%Resource{path: path, title: title}, _, _) do
    %{resource_path: path, resource_title: title}
  end
end
