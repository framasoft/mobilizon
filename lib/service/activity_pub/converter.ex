defmodule Mobilizon.Service.ActivityPub.Converter do
  @moduledoc """
  Converter behaviour

  This module allows to convert from ActivityStream format to our own internal one, and back
  """
  @callback as_to_model_data(map()) :: map()
  @callback model_to_as(struct()) :: map()
end
