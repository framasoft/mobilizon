defmodule Mobilizon.Storage.Ecto do
  @moduledoc """
  Mobilizon Ecto utils
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [fetch_change: 2, put_change: 3, get_field: 2]
  alias Ecto.{Changeset, Query}
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes

  @doc """
  Adds sort to the query.
  """
  @spec sort(Query.t(), atom, atom) :: Query.t()
  def sort(query, sort, direction) do
    from(query, order_by: [{^direction, ^sort}])
  end

  @doc """
  Ensure changeset contains an URL

  If there's a blank URL that's because we're doing the first insert.
  Most of the time just go with the given URL.
  """
  @spec ensure_url(Changeset.t(), atom()) :: Changeset.t()
  def ensure_url(%Changeset{data: %{url: nil}} = changeset, route) do
    case fetch_change(changeset, :url) do
      {:ok, _url} ->
        changeset

      :error ->
        generate_url(changeset, route)
    end
  end

  def ensure_url(%Changeset{} = changeset, _route), do: changeset

  @spec generate_url(Changeset.t(), atom()) :: Changeset.t()
  defp generate_url(%Changeset{} = changeset, route) do
    uuid = Ecto.UUID.generate()

    changeset
    |> put_change(:id, uuid)
    |> put_change(
      :url,
      apply(Routes, String.to_existing_atom("page_url"), [Endpoint, route, uuid])
    )
  end

  @spec maybe_add_published_at(Changeset.t()) :: Changeset.t()
  def maybe_add_published_at(%Changeset{} = changeset) do
    if is_nil(get_field(changeset, :published_at)) do
      put_change(changeset, :published_at, DateTime.utc_now() |> DateTime.truncate(:second))
    else
      changeset
    end
  end
end
