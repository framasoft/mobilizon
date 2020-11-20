defmodule Mobilizon.GraphQL.Resolvers.Picture do
  @moduledoc """
  Handles the picture-related GraphQL calls
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Media, Users}
  alias Mobilizon.Media.Picture
  alias Mobilizon.Users.User
  import Mobilizon.Web.Gettext

  @doc """
  Get picture for an event

  See Mobilizon.Web.Resolvers.Event.create_event/3
  """
  def picture(%{picture_id: picture_id} = _parent, _args, _resolution) do
    with {:ok, picture} <- do_fetch_picture(picture_id), do: {:ok, picture}
  end

  def picture(%{picture: picture} = _parent, _args, _resolution), do: {:ok, picture}
  def picture(_parent, %{id: picture_id}, _resolution), do: do_fetch_picture(picture_id)
  def picture(_parent, _args, _resolution), do: {:ok, nil}

  @spec do_fetch_picture(nil) :: {:error, nil}
  defp do_fetch_picture(nil), do: {:error, nil}

  @spec do_fetch_picture(String.t()) :: {:ok, Picture.t()} | {:error, :not_found}
  defp do_fetch_picture(picture_id) do
    case Media.get_picture(picture_id) do
      %Picture{id: id, file: file} ->
        {:ok,
         %{
           name: file.name,
           url: file.url,
           id: id,
           content_type: file.content_type,
           size: file.size
         }}

      nil ->
        {:error, :not_found}
    end
  end

  @spec upload_picture(map, map, map) :: {:ok, Picture.t()} | {:error, any}
  def upload_picture(
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
         {:ok, picture = %Picture{}} <-
           Media.create_picture(%{"file" => args, "actor_id" => actor_id}) do
      {:ok,
       %{
         name: picture.file.name,
         url: picture.file.url,
         id: picture.id,
         content_type: picture.file.content_type,
         size: picture.file.size
       }}
    else
      {:error, :mime_type_not_allowed} ->
        {:error, dgettext("errors", "File doesn't have an allowed MIME type.")}

      error ->
        {:error, error}
    end
  end

  def upload_picture(_parent, _args, _resolution), do: {:error, :unauthenticated}

  @doc """
  Remove a picture that the user owns
  """
  @spec remove_picture(map(), map(), map()) ::
          {:ok, Picture.t()}
          | {:error, :unauthorized}
          | {:error, :unauthenticated}
          | {:error, :not_found}
  def remove_picture(_parent, %{id: picture_id}, %{context: %{current_user: %User{} = user}}) do
    with {:picture, %Picture{actor_id: actor_id} = picture} <-
           {:picture, Media.get_picture(picture_id)},
         {:is_owned, %Actor{} = _actor} <- User.owns_actor(user, actor_id) do
      Media.delete_picture(picture)
    else
      {:picture, nil} -> {:error, :not_found}
      {:is_owned, _} -> {:error, :unauthorized}
    end
  end

  def remove_picture(_parent, _args, _resolution), do: {:error, :unauthenticated}
end
