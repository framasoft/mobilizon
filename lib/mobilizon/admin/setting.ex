defmodule Mobilizon.Admin.Setting do
  @moduledoc """
  A Key-Value settings table for basic settings
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset

  @required_attrs [:group, :name]
  @optional_attrs [:value]
  @attrs @required_attrs ++ @optional_attrs

  @type t :: %{
          group: String.t(),
          name: String.t(),
          value: String.t()
        }

  schema "admin_settings" do
    field(:group, :string)
    field(:name, :string)
    field(:value, :string)

    timestamps()
  end

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:group, name: :admin_settings_group_name_index)
  end
end

defmodule Mobilizon.Admin.SettingMedia do
  @moduledoc """
  A Key-Value settings table for media settings
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset
  alias Mobilizon.Federation.ActivityPub.Relay
  alias Mobilizon.Medias
  alias Mobilizon.Medias.Media
  alias Mobilizon.Storage.Repo

  @required_attrs [:group, :name]

  @type t :: %{
          group: String.t(),
          name: String.t(),
          media: Media.t()
        }

  schema "admin_settings_medias" do
    field(:group, :string)
    field(:name, :string)
    belongs_to(:media, Media, on_replace: :delete)

    timestamps()
  end

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(setting_media, attrs) do
    setting_media
    |> Repo.preload(:media)
    |> cast(attrs, @required_attrs)
    |> put_media(attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:group, name: :admin_settings_medias_group_name_index)
  end

  # # In case the provided media is an existing one
  @spec put_media(Changeset.t(), map) :: Changeset.t()
  defp put_media(%Changeset{} = changeset, %{media: %{media_id: id}}) do
    %Media{} = media = Medias.get_media!(id)
    put_assoc(changeset, :media, media)
  end

  # In case it's a new media
  defp put_media(%Changeset{} = changeset, %{media: %{media: media}}) do
    {:ok, media} = upload_media(media)
    put_assoc(changeset, :media, media)
  end

  # In case there is no media
  defp put_media(%Changeset{} = changeset, _media) do
    put_assoc(changeset, :media, nil)
  end

  import Mobilizon.Web.Gettext
  @spec upload_media(map) :: {:ok, Media.t()} | {:error, any}
  defp upload_media(%{file: %Plug.Upload{} = file} = args) do
    with {:ok,
          %{
            name: _name,
            url: url,
            content_type: content_type,
            size: size
          } = uploaded} <-
           Mobilizon.Web.Upload.store(file),
         args <-
           args
           |> Map.put(:url, url)
           |> Map.put(:size, size)
           |> Map.put(:content_type, content_type),
         {:ok, media = %Media{}} <-
           Medias.create_media(%{
             file: args,
             actor_id: Map.get(args, :actor_id, Relay.get_actor().id),
             metadata: Map.take(uploaded, [:width, :height, :blurhash])
           }) do
      {:ok, media}
    else
      {:error, :mime_type_not_allowed} ->
        {:error, dgettext("errors", "File doesn't have an allowed MIME type.")}

      error ->
        {:error, error}
    end
  end
end
