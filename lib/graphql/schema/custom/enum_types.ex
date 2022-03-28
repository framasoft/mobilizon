defmodule Mobilizon.GraphQL.Schema.Custom.EnumTypes do
  alias Absinthe.Blueprint.Schema
  alias Absinthe.Schema.Notation
  alias Absinthe.{Blueprint, Pipeline, Phase}

  @categories [
    %{
      id: :arts,
      label: "ARTS"
    },
    %{
      id: :book_clubs,
      label: "BOOK_CLUBS"
    },
    %{
      id: :business,
      label: "BUSINESS"
    },
    %{
      id: :causes,
      label: "CAUSES"
    },
    %{
      id: :comedy,
      label: "COMEDY"
    },
    %{
      id: :crafts,
      label: "CRAFTS"
    },
    %{
      id: :food_drink,
      label: "FOOD_DRINK"
    },
    %{
      id: :health,
      label: "HEALTH"
    },
    %{
      id: :music,
      label: "MUSIC"
    },
    %{
      id: :auto_boat_air,
      label: "AUTO_BOAT_AIR"
    },
    %{
      id: :community,
      label: "COMMUNITY"
    },
    %{
      id: :family_education,
      label: "FAMILY_EDUCATION"
    },
    %{
      id: :fashion_beauty,
      label: "FASHION_BEAUTY"
    },
    %{
      id: :film_media,
      label: "FILM_MEDIA"
    },
    %{
      id: :games,
      label: "GAMES"
    },
    # Legacy default value
    %{
      id: :meeting,
      label: "MEETING"
    }
  ]

  def pipeline(pipeline) do
    Pipeline.insert_after(pipeline, Phase.Schema.TypeImports, __MODULE__)
  end

  def run(blueprint = %Blueprint{}, _) do
    %{schema_definitions: [schema]} = blueprint

    new_enum = build_dynamic_enum()

    schema =
      Map.update!(schema, :type_definitions, fn type_definitions ->
        [new_enum | type_definitions]
      end)

    {:ok, %{blueprint | schema_definitions: [schema]}}
  end

  def build_dynamic_enum() do
    %Schema.EnumTypeDefinition{
      name: "EventCategory",
      identifier: :event_category,
      module: __MODULE__,
      __reference__: Notation.build_reference(__ENV__),
      values:
        Enum.map(@categories, fn %{id: id, label: label} ->
          %Schema.EnumValueDefinition{
            identifier: id,
            value: label,
            name: label,
            module: __MODULE__,
            __reference__: Notation.build_reference(__ENV__)
          }
        end)
    }
  end
end
