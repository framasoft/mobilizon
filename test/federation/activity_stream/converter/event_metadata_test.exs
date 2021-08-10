defmodule Mobilizon.Federation.ActivityStream.Converter.EventMetadataTest do
  @moduledoc """
  Module to test converting from EventMetadata to AS
  """
  use Mobilizon.DataCase
  import Mobilizon.Factory
  alias Mobilizon.Events.EventMetadata
  alias Mobilizon.Federation.ActivityStream.Converter.EventMetadata, as: EventMetadataConverter

  @property_value "PropertyValue"

  describe "metadata_to_as/1" do
    test "convert a simple metadata" do
      %EventMetadata{} = metadata = build(:event_metadata)

      assert %{"propertyID" => metadata.key, "value" => metadata.value, "type" => @property_value} ==
               EventMetadataConverter.metadata_to_as(metadata)
    end

    test "convert a boolean" do
      %EventMetadata{} = metadata = build(:event_metadata, type: :boolean, value: "false")

      assert %{"propertyID" => metadata.key, "value" => false, "type" => @property_value} ==
               EventMetadataConverter.metadata_to_as(metadata)
    end

    test "convert an integer" do
      %EventMetadata{} = metadata = build(:event_metadata, type: :integer, value: "36")

      assert %{"propertyID" => metadata.key, "value" => 36, "type" => @property_value} ==
               EventMetadataConverter.metadata_to_as(metadata)
    end

    test "convert a float" do
      %EventMetadata{} = metadata = build(:event_metadata, type: :float, value: "36.53")

      assert %{"propertyID" => metadata.key, "value" => 36.53, "type" => @property_value} ==
               EventMetadataConverter.metadata_to_as(metadata)
    end

    test "convert custom metadata with title" do
      %EventMetadata{} = metadata = build(:event_metadata, title: "hello")

      assert %{
               "propertyID" => metadata.key,
               "value" => metadata.value,
               "name" => "hello",
               "type" => @property_value
             } ==
               EventMetadataConverter.metadata_to_as(metadata)
    end
  end

  describe "as_to_metadata/1" do
    test "parse a simple metadata" do
      assert %{key: "somekey", value: "somevalue", type: :string} ==
               EventMetadataConverter.as_to_metadata(%{
                 "propertyID" => "somekey",
                 "value" => "somevalue",
                 "type" => @property_value
               })
    end

    test "parse a boolean metadata" do
      assert %{key: "somekey", value: "false", type: :boolean} ==
               EventMetadataConverter.as_to_metadata(%{
                 "propertyID" => "somekey",
                 "value" => false,
                 "type" => @property_value
               })
    end

    test "parse an integer metadata" do
      assert %{key: "somekey", value: "4", type: :integer} ==
               EventMetadataConverter.as_to_metadata(%{
                 "propertyID" => "somekey",
                 "value" => 4,
                 "type" => @property_value
               })
    end

    test "parse a float metadata" do
      assert %{key: "somekey", value: "4.36", type: :float} ==
               EventMetadataConverter.as_to_metadata(%{
                 "propertyID" => "somekey",
                 "value" => 4.36,
                 "type" => @property_value
               })
    end

    test "parse a custom metadata with title" do
      assert %{key: "somekey", value: "somevalue", type: :string, title: "title"} ==
               EventMetadataConverter.as_to_metadata(%{
                 "propertyID" => "somekey",
                 "value" => "somevalue",
                 "name" => "title",
                 "type" => @property_value
               })
    end
  end
end
