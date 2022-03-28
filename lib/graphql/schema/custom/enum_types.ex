defmodule Mobilizon.GraphQL.Schema.Custom.EnumTypes do
  @moduledoc """
  Register extra enum types dynamically
  """
  alias Absinthe.Blueprint.Schema
  alias Absinthe.Schema.Notation
  alias Absinthe.{Blueprint, Phase, Pipeline}
  alias Mobilizon.Events.Categories

  def pipeline(pipeline) do
    Pipeline.insert_after(pipeline, Phase.Schema.TypeImports, __MODULE__)
  end

  @spec run(Absinthe.Blueprint.t(), any()) :: {:ok, Absinthe.Blueprint.t()}
  def run(%Blueprint{} = blueprint, _) do
    %{schema_definitions: [schema]} = blueprint

    new_enum = build_dynamic_enum()

    schema =
      Map.update!(schema, :type_definitions, fn type_definitions ->
        [new_enum | type_definitions]
      end)

    {:ok, %{blueprint | schema_definitions: [schema]}}
  end

  @spec build_dynamic_enum :: Absinthe.Blueprint.Schema.EnumTypeDefinition.t()
  defp build_dynamic_enum do
    %Schema.EnumTypeDefinition{
      name: "EventCategory",
      identifier: :event_category,
      module: __MODULE__,
      __reference__: Notation.build_reference(__ENV__),
      values:
        Enum.map(Categories.list(), fn %{id: id} ->
          %Schema.EnumValueDefinition{
            identifier: id,
            value: String.upcase(to_string(id)),
            name: String.upcase(to_string(id)),
            module: __MODULE__,
            __reference__: Notation.build_reference(__ENV__)
          }
        end)
    }
  end
end
