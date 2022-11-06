defmodule Mobilizon.GraphQL.Middleware.OperationNameLogger do
  @moduledoc """
  An Absinthe middleware to add to logging providers the GraphQL Operation name as context
  """

  @behaviour Absinthe.Middleware
  alias Absinthe.Blueprint.Document.Operation

  def call(resolution, _opts) do
    case Enum.find(resolution.path, &current_operation?/1) do
      %Operation{name: name} when not is_nil(name) ->
        Logger.metadata(graphql_operation_name: name)

        if Application.get_env(:sentry, :dsn) != nil do
          Sentry.Context.set_extra_context(%{"graphql_operation_name" => name})
        end

      _ ->
        Logger.metadata(graphql_operation_name: "#NULL")
    end

    resolution
  end

  defp current_operation?(%Operation{current: true}), do: true
  defp current_operation?(_), do: false
end
