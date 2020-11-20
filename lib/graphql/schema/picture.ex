defmodule Mobilizon.GraphQL.Schema.PictureType do
  @moduledoc """
  Schema representation for Pictures
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.Picture

  @desc "A picture"
  object :picture do
    field(:id, :id, description: "The picture's ID")
    field(:alt, :string, description: "The picture's alternative text")
    field(:name, :string, description: "The picture's name")
    field(:url, :string, description: "The picture's full URL")
    field(:content_type, :string, description: "The picture's detected content type")
    field(:size, :integer, description: "The picture's size")
  end

  @desc "An attached picture or a link to a picture"
  input_object :picture_input do
    # Either a full picture object
    field(:picture, :picture_input_object, description: "A full picture attached")
    # Or directly the ID of an existing picture
    field(:picture_id, :id, description: "The ID of an existing picture")
  end

  @desc "An attached picture"
  input_object :picture_input_object do
    field(:name, non_null(:string), description: "The picture's name")
    field(:alt, :string, description: "The picture's alternative text")
    field(:file, non_null(:upload), description: "The picture file")
    field(:actor_id, :id, description: "The picture owner")
  end

  object :picture_queries do
    @desc "Get a picture"
    field :picture, :picture do
      arg(:id, non_null(:id), description: "The picture ID")
      resolve(&Picture.picture/3)
    end
  end

  object :picture_mutations do
    @desc "Upload a picture"
    field :upload_picture, :picture do
      arg(:name, non_null(:string), description: "The picture's name")
      arg(:alt, :string, description: "The picture's alternative text")
      arg(:file, non_null(:upload), description: "The picture file")
      resolve(&Picture.upload_picture/3)
    end

    @desc """
    Remove a picture
    """
    field :remove_picture, :deleted_object do
      arg(:id, non_null(:id), description: "The picture's ID")
      resolve(&Picture.remove_picture/3)
    end
  end
end
