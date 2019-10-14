defmodule MobilizonWeb.Schema.PictureType do
  @moduledoc """
  Schema representation for Pictures
  """
  use Absinthe.Schema.Notation
  alias MobilizonWeb.Resolvers.Picture

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
    field(:picture, :picture_input_object)
    # Or directly the ID of an existing picture
    field(:picture_id, :id)
  end

  @desc "An attached picture"
  input_object :picture_input_object do
    field(:name, non_null(:string))
    field(:alt, :string)
    field(:file, non_null(:upload))
    field(:actor_id, :id)
  end

  object :picture_queries do
    @desc "Get a picture"
    field :picture, :picture do
      arg(:id, non_null(:string))
      resolve(&Picture.picture/3)
    end
  end

  object :picture_mutations do
    @desc "Upload a picture"
    field :upload_picture, :picture do
      arg(:name, non_null(:string))
      arg(:alt, :string)
      arg(:file, non_null(:upload))
      arg(:actor_id, non_null(:id))
      resolve(&Picture.upload_picture/3)
    end
  end
end
