defmodule Mobilizon.Federation.ActivityStream do
  @moduledoc """
  The ActivityStream Type
  """

  @type t :: %{String.t() => String.t() | list(String.t()) | map() | nil}
end
