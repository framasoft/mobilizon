defmodule Mobilizon.Storage.Ecto do
  @moduledoc """
  Mobilizon Ecto utils
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [fetch_change: 2, put_change: 3, get_field: 2]
  alias Ecto.{Changeset, Query}
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Gettext, as: GettextBackend
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

  def convert_ecto_errors(%Ecto.Changeset{} = changeset),
    do: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)

  # Translates an error message using gettext.
  defp translate_error({msg, opts}) do
    # Because error messages were defined within Ecto, we must
    # call the Gettext module passing our Gettext backend. We
    # also use the "errors" domain as translations are placed
    # in the errors.po file.
    # Ecto will pass the :count keyword if the error message is
    # meant to be pluralized.
    # On your own code and templates, depending on whether you
    # need the message to be pluralized or not, this could be
    # written simply as:
    #
    #     dngettext "errors", "1 file", "%{count} files", count
    #     dgettext "errors", "is invalid"
    #

    if count = opts[:count] do
      Gettext.dngettext(GettextBackend, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(GettextBackend, "errors", msg, opts)
    end
  end
end
