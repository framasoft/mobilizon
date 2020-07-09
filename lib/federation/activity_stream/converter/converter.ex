defmodule Mobilizon.Federation.ActivityStream.Converter do
  @moduledoc """
  Converter behaviour.

  This module allows to convert from ActivityStream format to our own internal
  one, and back.
  """

  @type model_data :: map()

  @callback as_to_model_data(as_data :: ActivityStream.t()) :: model_data()
  @callback model_to_as(model :: struct()) :: ActivityStream.t()
end
