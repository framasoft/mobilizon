defmodule Mobilizon.GraphQL.AbsintheHelpers do
  @moduledoc """
  Absinthe helpers for tests
  """

  import Phoenix.ConnTest

  alias Plug.Conn

  @endpoint Mobilizon.Web.Endpoint

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

  @spec graphql_query(Conn.t(), Keyword.t()) :: map | no_return
  def graphql_query(conn, options) do
    conn
    |> post("/api", build_query(options[:query], Keyword.get(options, :variables, %{})))
    |> json_response(200)
  end

  defp build_query(query, variables) do
    %{
      "query" => query,
      "variables" => variables
    }
  end
end
