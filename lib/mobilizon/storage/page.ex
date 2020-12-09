defmodule Mobilizon.Storage.Page do
  @moduledoc """
  Module for pagination of queries.
  """

  import Ecto.Query

  alias Mobilizon.Storage.Repo

  defstruct [
    :total,
    :elements
  ]

  @type t :: %__MODULE__{
          total: integer,
          elements: struct
        }

  @doc """
  Returns a Page struct for a query.

  `field` is use to define the field that will be used for the count aggregate, which should be the same as the field used for order_by
    See https://stackoverflow.com/q/12693089/10204399
  """
  @spec build_page(Ecto.Query.t(), integer | nil, integer | nil, atom()) :: t
  def build_page(query, page, limit, field \\ :id) do
    [total, elements] =
      [
        fn -> Repo.aggregate(query, :count, field) end,
        fn -> Repo.all(paginate(query, page, limit)) end
      ]
      |> Enum.map(&Task.async/1)
      |> Enum.map(&Task.await/1)

    %__MODULE__{total: total, elements: elements}
  end

  @doc """
  Add limit and offset to the query.
  """
  @spec paginate(Ecto.Query.t() | struct, integer | nil, integer | nil) :: Ecto.Query.t()
  def paginate(query, page \\ 1, size \\ 10)

  def paginate(query, page, _size) when is_nil(page), do: paginate(query)
  def paginate(query, page, size) when is_nil(size), do: paginate(query, page)

  def paginate(query, page, size) do
    from(query, limit: ^size, offset: ^((page - 1) * size))
  end
end
