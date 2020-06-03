defmodule Mobilizon.Storage.Ecto do
  @moduledoc """
  Mobilizon Ecto utils
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [fetch_change: 2, put_change: 3]
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes

  @doc """
  Adds sort to the query.
  """
  @spec sort(Ecto.Query.t(), atom, atom) :: Ecto.Query.t()
  def sort(query, sort, direction) do
    from(query, order_by: [{^direction, ^sort}])
  end

  @doc """
  Ensure changeset contains an URL

  If there's a blank URL that's because we're doing the first insert.
  Most of the time just go with the given URL.
  """
  @spec ensure_url(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def ensure_url(%Ecto.Changeset{data: %{url: nil}} = changeset, route) do
    case fetch_change(changeset, :url) do
      {:ok, _url} ->
        changeset

      :error ->
        generate_url(changeset, route)
    end
  end

  def ensure_url(%Ecto.Changeset{} = changeset, _route), do: changeset

  @spec generate_url(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  defp generate_url(%Ecto.Changeset{} = changeset, route) do
    uuid = Ecto.UUID.generate()

    changeset
    |> put_change(:id, uuid)
    |> put_change(
      :url,
      apply(Routes, String.to_existing_atom("#{to_string(route)}_url"), [Endpoint, route, uuid])
    )
  end
end
