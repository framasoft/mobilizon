defmodule MobilizonWeb.Schema.SortType do
  @moduledoc """
  Allows sorting a collection of elements
  """
  use Absinthe.Schema.Notation

  @desc "Available sort directions"
  enum :sort_direction do
    value(:asc)
    value(:desc)
  end
end
