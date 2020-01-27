defmodule Mobilizon.GraphQL.Resolvers.Picture do
  @moduledoc """
  Handles the picture-related GraphQL calls
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Media
  alias Mobilizon.Media.Picture
  alias Mobilizon.Users.User

  @doc """
  Get picture for an event's pic
  """
  def picture(%{picture_id: picture_id} = _parent, _args, _resolution) do
    with {:ok, picture} <- do_fetch_picture(picture_id), do: {:ok, picture}
  end

  @doc """
  Get picture for an event that has an attached

  See Mobilizon.Web.Resolvers.Event.create_event/3
  """
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

      _error ->
        {:error, "Picture with ID #{picture_id} was not found"}
    end
  end

  @spec upload_picture(map, map, map) :: {:ok, Picture.t()} | {:error, any}
  def upload_picture(
        _parent,
        %{file: %Plug.Upload{} = file, actor_id: actor_id} = args,
        %{context: %{current_user: user}}
      ) do
    with {:is_owned, %Actor{}} <- User.owns_actor(user, actor_id),
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
      {:is_owned, nil} ->
        {:error, "Actor id is not owned by authenticated user"}

      error ->
        {:error, error}
    end
  end

  def upload_picture(_parent, _args, _resolution) do
    {:error, "You need to login to upload a picture"}
  end
end
