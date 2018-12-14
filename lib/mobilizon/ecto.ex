defmodule Mobilizon.Ecto do
  @moduledoc """
  Mobilizon Ecto utils
  """

  import Ecto.Query, warn: false

  @doc """
  Add limit and offset to the query
  """
  def paginate(query, page \\ 1, size \\ 10)
  def paginate(query, page, _size) when is_nil(page), do: paginate(query)
  def paginate(query, page, size) when is_nil(size), do: paginate(query, page)

  def paginate(query, page, size) do
    from(query,
      limit: ^size,
      offset: ^((page - 1) * size)
    )
  end

  def increment_slug(slug) do
    case List.pop_at(String.split(slug, "-"), -1) do
      {nil, _} ->
        slug

      {suffix, slug_parts} ->
        case Integer.parse(suffix) do
          {id, _} -> Enum.join(slug_parts, "-") <> "-" <> Integer.to_string(id + 1)
          :error -> slug <> "-1"
        end
    end
  end
end
