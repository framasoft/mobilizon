defmodule MobilizonWeb.AbsintheHelpers do
  use Phoenix.ConnTest
  @endpoint MobilizonWeb.Endpoint

  @moduledoc """
  Absinthe helpers for tests
  """
  def query_skeleton(query, query_name) do
    %{
      "operationName" => "#{query_name}",
      "query" => "query #{query_name} #{query}",
      "variables" => "{}"
    }
  end

  def mutation_skeleton(query) do
    %{
      "operationName" => "",
      "query" => "#{query}",
      "variables" => ""
    }
  end

  def graphql_query(conn, options) do
    conn
    |> post(
      "/api",
      build_query(options[:query], Keyword.get(options, :variables, %{}))
    )
    |> json_response(200)
  end

  defp build_query(query, variables) do
    %{
      "query" => query,
      "variables" => variables
    }
  end
end
