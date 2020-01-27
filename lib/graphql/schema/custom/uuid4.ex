defmodule Mobilizon.GraphQL.Schema.Custom.UUID do
  @moduledoc """
  The UUID4 scalar type allows UUID compliant strings to be passed in and out.
  Requires `{ :ecto, ">= 0.0.0" }` package: https://github.com/elixir-ecto/ecto
  """
  use Absinthe.Schema.Notation

  alias Ecto.UUID

  scalar :uuid, name: "UUID" do
    description("""
    The `UUID` scalar type represents UUID4 compliant string data, represented as UTF-8
    character sequences. The UUID4 type is most often used to represent unique
    human-readable ID strings.
    """)

    serialize(&encode/1)
    parse(&decode/1)
  end

  @spec decode(Absinthe.Blueprint.Input.String.t()) :: {:ok, term} | :error
  @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
    UUID.cast(value)
  end

  defp decode(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp decode(_) do
    :error
  end

  defp encode(value), do: value
end
