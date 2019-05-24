defmodule MobilizonWeb.Resolvers.Picture do
  @moduledoc """
  Handles the picture-related GraphQL calls
  """
  alias Mobilizon.Media
  alias Mobilizon.Media.Picture

  @doc """
  Get picture for an event's pic
  """
  def picture(%{picture_id: picture_id} = _parent, _args, _resolution) do
    with {:ok, picture} <- do_fetch_picture(picture_id) do
      {:ok, picture}
    end
  end

  @doc """
  Get picture for an event that has an attached

  See MobilizonWeb.Resolvers.Event.create_event/3
  """
  def picture(%{picture: picture} = _parent, _args, _resolution) do
    {:ok, picture}
  end

  def picture(_parent, %{id: picture_id}, _resolution), do: do_fetch_picture(picture_id)

  def picture(_parent, _args, _resolution) do
    {:ok, nil}
  end

  @spec do_fetch_picture(nil) :: {:error, nil}
  defp do_fetch_picture(nil), do: {:error, nil}

  @spec do_fetch_picture(String.t()) :: {:ok, Picture.t()} | {:error, :not_found}
  defp do_fetch_picture(picture_id) do
    with %Picture{id: id, file: file} = _pic <- Media.get_picture(picture_id) do
      {:ok, %{name: file.name, url: file.url, id: id}}
    else
      _err ->
        {:error, "Picture with ID #{picture_id} was not found"}
    end
  end

  @spec upload_picture(map(), map(), map()) :: {:ok, Picture.t()} | {:error, any()}
  def upload_picture(_parent, %{file: %Plug.Upload{} = file} = args, %{
        context: %{
          current_user: _user
        }
      }) do
    with {:ok, %{"url" => [%{"href" => url}]}} <- MobilizonWeb.Upload.store(file),
         args <- Map.put(args, :url, url),
         {:ok, picture = %Picture{}} <- Media.create_picture(%{"file" => args}) do
      {:ok, %{name: picture.file.name, url: picture.file.url, id: picture.id}}
    else
      err ->
        {:error, err}
    end
  end

  def upload_picture(_parent, _args, _resolution) do
    {:error, "You need to login to upload a picture"}
  end
end
