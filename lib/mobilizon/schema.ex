defmodule Mobilizon.Ecto.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @timestamps_opts [type: :naive_datetime]
    end
  end
end
