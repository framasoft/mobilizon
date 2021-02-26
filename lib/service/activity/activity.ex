defmodule Mobilizon.Service.Activity do
  @moduledoc """
  Behavior for Activity creators
  """

  @callback insert_activity(entity :: struct(), options :: map()) :: {:ok, Oban.Job.t()}
end
