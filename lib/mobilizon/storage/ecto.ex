defmodule Mobilizon.Storage.Ecto do
  @moduledoc """
  Mobilizon Ecto utils
  """

  import Ecto.Query, warn: false

  @doc """
  Adds sort to the query.
  """
  @spec sort(Ecto.Query.t(), atom, atom) :: Ecto.Query.t()
  def sort(query, sort, direction) do
    from(query, order_by: [{^direction, ^sort}])
  end
end
