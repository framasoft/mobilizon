defmodule Mobilizon.GraphQL.Schema.Custom.Timezone do
  @moduledoc """
  The timezone scalar type allows timezone ID strings to be passed in and out.
  """
  use Absinthe.Schema.Notation
  import Mobilizon.Web.Gettext, only: [dgettext: 3]

  scalar :timezone, name: "Timezone" do
    description("""
    The `Timezone` scalar type represents a timezone identifier,
    as registered in the IANA Time Zone Database.
    """)

    serialize(&encode/1)
    parse(&decode/1)
  end

  @spec decode(Absinthe.Blueprint.Input.String.t()) :: {:ok, term} | :error
  @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp decode(%Absinthe.Blueprint.Input.String{value: ""}), do: {:ok, nil}

  defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
    if Tzdata.zone_exists?(value),
      do: {:ok, value},
      else: {:error, dgettext("errors", "Timezone ID %{timezone} is invalid", timezone: value)}
  end

  defp decode(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp decode(_) do
    :error
  end

  defp encode(value), do: value
end
