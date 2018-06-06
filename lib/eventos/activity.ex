defmodule Eventos.Activity do
  @moduledoc """
  Represents an activity
  """

  defstruct [:id, :data, :local, :actor, :recipients, :notifications]
end
