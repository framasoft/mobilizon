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

  @type t(structure) :: %__MODULE__{
          total: integer,
          elements: list(structure)
        }

  @doc """
  Returns a Page struct for a query.
  """
  @spec build_page(Ecto.Queryable.t(), integer | nil, integer) :: t(any)
  def build_page(query, page, limit) do
    count_query =
      query
      # Exclude select because we add a new one below
      |> exclude(:select)
      # Exclude order_by for perf
      |> exclude(:order_by)
      # Exclude preloads to avoid error "cannot preload associations in subquery"
      |> exclude(:preload)
      |> subquery()
      |> select([r], count(fragment("*")))

    [total, elements] =
      [
        fn -> Repo.one(count_query) end,
        fn -> Repo.all(paginate(query, page, limit)) end
      ]
      |> Enum.map(&Task.async/1)
      |> Enum.map(&Task.await(&1, 30_000))

    %__MODULE__{total: total, elements: elements}
  end

  @doc """
  Add limit and offset to the query.
  """
  @spec paginate(Ecto.Queryable.t() | struct, integer | nil, integer | nil) :: Ecto.Query.t()
  def paginate(query, page \\ 1, size \\ 10)

  def paginate(query, page, _size) when is_nil(page), do: paginate(query)
  def paginate(query, page, size) when is_nil(size), do: paginate(query, page)

  def paginate(query, page, size) do
    from(query, limit: ^size, offset: ^((page - 1) * size))
  end

  @doc """
  Stream chunks of results from the given queryable.

  Unlike Repo.stream, this function does not keep a long running transaction open.
  Hence, consistency is not guarenteed in the presence of rows being deleted or sort criteria changing.

  ## Example

    Ecto.Query.from(u in Users, order_by: [asc: :created_at])
    |> Repo.chunk(100)
    |> Stream.map(&process_batch_of_users)
    |> Stream.run()

  ## Source
  https://elixirforum.com/t/what-is-the-best-approach-for-fetching-large-amount-of-records-from-postgresql-with-ecto/3766/8
  """
  @spec chunk(Ecto.Queryable.t(), integer) :: Stream.t()
  def chunk(queryable, chunk_size) do
    chunk_stream =
      Stream.unfold(1, fn page_number ->
        page = queryable |> paginate(page_number, chunk_size) |> Repo.all()
        {page, page_number + 1}
      end)

    Stream.take_while(chunk_stream, fn
      [] -> false
      _ -> true
    end)
  end
end
