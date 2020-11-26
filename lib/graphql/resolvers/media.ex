defmodule Mobilizon.GraphQL.Resolvers.Media do
  @moduledoc """
  Handles the media-related GraphQL calls
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Medias, Users}
  alias Mobilizon.Medias.Media
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  @doc """
  Get media for an event

  See Mobilizon.Web.Resolvers.Event.create_event/3
  """
  def media(%{picture_id: media_id} = _parent, _args, _resolution) do
    with {:ok, media} <- do_fetch_media(media_id), do: {:ok, media}
  end

  def media(%{picture: media} = _parent, _args, _resolution), do: {:ok, media}
  def media(_parent, %{id: media_id}, _resolution), do: do_fetch_media(media_id)
  def media(_parent, _args, _resolution), do: {:ok, nil}

  def medias(%{media: medias}, _args, _resolution) do
    {:ok, Enum.map(medias, &transform_media/1)}
  end

  @spec do_fetch_media(nil) :: {:error, nil}
  defp do_fetch_media(nil), do: {:error, nil}

  @spec do_fetch_media(String.t()) :: {:ok, Media.t()} | {:error, :not_found}
  defp do_fetch_media(media_id) do
    case Medias.get_media(media_id) do
      %Media{} = media ->
        {:ok, transform_media(media)}

      nil ->
        {:error, :not_found}
    end
  end

  @spec upload_media(map, map, map) :: {:ok, Media.t()} | {:error, any}
  def upload_media(
        _parent,
        %{file: %Plug.Upload{} = file} = args,
        %{context: %{current_user: %User{} = user}}
      ) do
    with %Actor{id: actor_id} <- Users.get_actor_for_user(user),
         {:ok, %{name: _name, url: url, content_type: content_type, size: size}} <-
           Mobilizon.Web.Upload.store(file),
         args <-
           args
           |> Map.put(:url, url)
           |> Map.put(:size, size)
           |> Map.put(:content_type, content_type),
         {:ok, media = %Media{}} <-
           Medias.create_media(%{"file" => args, "actor_id" => actor_id}) do
      {:ok, transform_media(media)}
    else
      {:error, :mime_type_not_allowed} ->
        {:error, dgettext("errors", "File doesn't have an allowed MIME type.")}

      error ->
        {:error, error}
    end
  end

  def upload_media(_parent, _args, _resolution), do: {:error, :unauthenticated}

  @doc """
  Remove a media that the user owns
  """
  @spec remove_media(map(), map(), map()) ::
          {:ok, Media.t()}
          | {:error, :unauthorized}
          | {:error, :unauthenticated}
          | {:error, :not_found}
  def remove_media(_parent, %{id: media_id}, %{context: %{current_user: %User{} = user}}) do
    with {:media, %Media{actor_id: actor_id} = media} <-
           {:media, Medias.get_media(media_id)},
         {:is_owned, %Actor{} = _actor} <- User.owns_actor(user, actor_id) do
      Medias.delete_media(media)
    else
      {:media, nil} -> {:error, :not_found}
      {:is_owned, _} -> {:error, :unauthorized}
    end
  end

  def remove_media(_parent, _args, _resolution), do: {:error, :unauthenticated}

  @doc """
  Return the total media size for an actor
  """
  @spec actor_size(map(), map(), map()) ::
          {:ok, integer()} | {:error, :unauthorized} | {:error, :unauthenticated}
  def actor_size(%Actor{id: actor_id}, _args, %{
        context: %{current_user: %User{} = user}
      }) do
    if can_get_actor_size?(user, actor_id) do
      {:ok, Medias.media_size_for_actor(actor_id)}
    else
      {:error, :unauthorized}
    end
  end

  def actor_size(_parent, _args, _resolution), do: {:error, :unauthenticated}

  @doc """
  Return the total media size for a local user
  """
  @spec user_size(map(), map(), map()) ::
          {:ok, integer()} | {:error, :unauthorized} | {:error, :unauthenticated}
  def user_size(%User{id: user_id}, _args, %{
        context: %{current_user: %User{} = logged_user}
      }) do
    if can_get_user_size?(logged_user, user_id) do
      {:ok, Medias.media_size_for_user(user_id)}
    else
      {:error, :unauthorized}
    end
  end

  def user_size(_parent, _args, _resolution), do: {:error, :unauthenticated}

  @spec transform_media(Media.t()) :: map()
  defp transform_media(%Media{id: id, file: file}) do
    %{
      name: file.name,
      url: file.url,
      id: id,
      content_type: file.content_type,
      size: file.size
    }
  end

  @spec can_get_user_size?(User.t(), integer()) :: boolean()
  defp can_get_actor_size?(%User{role: role} = user, actor_id) do
    role in [:moderator, :administrator] || owns_actor?(User.owns_actor(user, actor_id))
  end

  @spec owns_actor?({:is_owned, Actor.t() | nil}) :: boolean()
  defp owns_actor?({:is_owned, %Actor{} = _actor}), do: true
  defp owns_actor?({:is_owned, _}), do: false

  @spec can_get_user_size?(User.t(), integer()) :: boolean()
  defp can_get_user_size?(%User{role: role, id: logged_user_id}, user_id) do
    user_id == logged_user_id || role in [:moderator, :administrator]
  end
end
