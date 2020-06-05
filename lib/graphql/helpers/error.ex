defmodule Mobilizon.GraphQL.Helpers.Error do
  @moduledoc """
  Helper functions for Mobilizon.GraphQL
  """
  alias Ecto.Changeset

  def handle_errors(fun) do
    fn source, args, info ->
      case Absinthe.Resolution.call(fun, source, args, info) do
        {:error, %Changeset{} = changeset} ->
          format_changeset(changeset)

        {:error, _, %Changeset{} = changeset} ->
          format_changeset(changeset)

        val ->
          val
      end
    end
  end

  def format_changeset(%Changeset{changes: changes} = changeset) do
    # {:error, [email: {"has already been taken", []}]}

    errors =
      Enum.reduce(changes, [], fn {_key, value}, acc ->
        case value do
          %Changeset{} ->
            {:error, errors} = format_changeset(value)
            acc ++ errors

          _ ->
            acc
        end
      end)

    errors = errors ++ Enum.map(changeset.errors, &transform_error/1)

    {:error, errors}
  end

  defp transform_error({key, {value, _context}}) do
    [message: "#{value}", details: key]
  end
end
