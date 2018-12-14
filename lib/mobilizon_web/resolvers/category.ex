defmodule MobilizonWeb.Resolvers.Category do
  require Logger
  alias Mobilizon.Actors.User

  def list_categories(_parent, %{page: page, limit: limit}, _resolution) do
    categories =
      Mobilizon.Events.list_categories(page, limit)
      |> Enum.map(fn category ->
        urls = MobilizonWeb.Uploaders.Category.urls({category.picture, category})
        Map.put(category, :picture, %{url: urls.original, url_thumbnail: urls.thumb})
      end)

    {:ok, categories}
  end

  def create_category(_parent, %{title: title, picture: picture, description: description}, %{
        context: %{current_user: %User{} = _user}
      }) do
    with {:ok, category} <-
           Mobilizon.Events.create_category(%{
             title: title,
             description: description,
             picture: picture
           }),
         urls <- MobilizonWeb.Uploaders.Category.urls({category.picture, category}) do
      Logger.info("Created category " <> title)
      {:ok, Map.put(category, :picture, %{url: urls.original, url_thumbnail: urls.thumb})}
    else
      {:error, %Ecto.Changeset{errors: errors} = _changeset} ->
        # This is pretty ridiculous for changeset to error
        errors =
          Enum.into(errors, %{})
          |> Enum.map(fn {key, {value, _}} -> Atom.to_string(key) <> ": " <> value end)

        {:error, errors}
    end
  end

  def create_category(_parent, _args, %{}) do
    {:error, "You are not allowed to create a category if not connected"}
  end
end
