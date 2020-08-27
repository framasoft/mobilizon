defmodule Mobilizon.Federation.ActivityPub.Types.Actors do
  @moduledoc false
  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub.Audience
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.GraphQL.API.Utils, as: APIUtils
  alias Mobilizon.Service.Formatter.HTML
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_create_data: 2, make_update_data: 2]

  @behaviour Entity

  @impl Entity
  @spec create(map(), map()) :: {:ok, map()}
  def create(args, additional) do
    with args <- prepare_args_for_actor(args),
         {:ok, %Actor{} = actor} <- Actors.create_actor(args),
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

  defp prepare_args_for_actor(args) do
    with preferred_username <-
           args |> Map.get(:preferred_username) |> HTML.strip_tags() |> String.trim(),
         summary <- args |> Map.get(:summary, "") |> String.trim(),
         {summary, _mentions, _tags} <-
           summary |> String.trim() |> APIUtils.make_content_html([], "text/html") do
      %{args | preferred_username: preferred_username, summary: summary}
    end
  end
end
