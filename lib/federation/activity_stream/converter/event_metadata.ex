defmodule Mobilizon.Federation.ActivityStream.Converter.EventMetadata do
  @moduledoc """
  Module to convert and validate event metadata
  """

  alias Mobilizon.Events.EventMetadata
  alias Mobilizon.Federation.ActivityStream

  @property_value "PropertyValue"

  @spec metadata_to_as(EventMetadata.t()) :: map()
  def metadata_to_as(%EventMetadata{type: :boolean, value: value, key: key})
      when value in ["true", "false"] do
    %{
      "type" => @property_value,
      "propertyID" => key,
      "value" => String.to_existing_atom(value)
    }
  end

  def metadata_to_as(%EventMetadata{type: :integer, value: value, key: key}) do
    %{
      "type" => @property_value,
      "propertyID" => key,
      "value" => String.to_integer(value)
    }
  end

  def metadata_to_as(%EventMetadata{type: :float, value: value, key: key}) do
    {value, _} = Float.parse(value)

    %{
      "type" => @property_value,
      "propertyID" => key,
      "value" => value
    }
  end

  def metadata_to_as(%EventMetadata{type: :string, value: value, key: key} = metadata) do
    additional = if is_nil(metadata.title), do: %{}, else: %{"name" => metadata.title}

    Map.merge(
      %{
        "type" => @property_value,
        "propertyID" => key,
        "value" => value
      },
      additional
    )
  end

  @spec as_to_metadata(ActivityStream.t()) :: map()
  def as_to_metadata(%{"type" => @property_value, "propertyID" => key, "value" => value})
      when is_boolean(value) do
    %{type: :boolean, key: key, value: to_string(value)}
  end

  def as_to_metadata(%{"type" => @property_value, "propertyID" => key, "value" => value})
      when is_float(value) do
    %{type: :float, key: key, value: to_string(value)}
  end

  def as_to_metadata(%{"type" => @property_value, "propertyID" => key, "value" => value})
      when is_integer(value) do
    %{type: :integer, key: key, value: to_string(value)}
  end

  def as_to_metadata(%{"type" => @property_value, "propertyID" => key, "value" => value} = args)
      when is_binary(value) do
    additional = if Map.has_key?(args, "name"), do: %{title: Map.get(args, "name")}, else: %{}
    Map.merge(%{type: :string, key: key, value: value}, additional)
  end
end
