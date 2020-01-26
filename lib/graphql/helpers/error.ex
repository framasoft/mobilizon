defmodule Mobilizon.GraphQL.Helpers.Error do
  @moduledoc """
  Helper functions for Mobilizon.GraphQL
  """

  def handle_errors(fun) do
    fn source, args, info ->
      case Absinthe.Resolution.call(fun, source, args, info) do
        {:error, %Ecto.Changeset{} = changeset} -> format_changeset(changeset)
        val -> val
      end
    end
  end

  def format_changeset(changeset) do
    # {:error, [email: {"has already been taken", []}]}
    errors =
      changeset.errors
      |> Enum.map(fn {key, {value, _context}} ->
        [message: "#{value}", details: key]
      end)

    {:error, errors}
  end
end
