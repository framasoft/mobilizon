defmodule Mobilizon.GraphQL.Schema.ResourceType do
  @moduledoc """
  Schema representation for Resources
  """
  use Absinthe.Schema.Notation
  alias Mobilizon.GraphQL.Resolvers.Resource
  alias Mobilizon.Resources
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  @desc "A resource"
  object :resource do
    field(:id, :id, description: "The resource's ID")
    field(:title, :string, description: "The resource's title")
    field(:summary, :string, description: "The resource's summary")
    field(:url, :string, description: "The resource's URL")
    field(:resource_url, :string, description: "The resource's URL")
    field(:metadata, :resource_metadata, description: "The resource's metadata")
    field(:creator, :actor, description: "The resource's creator")
    field(:actor, :actor, description: "The resource's owner")
    field(:inserted_at, :naive_datetime, description: "The resource's creation date")
    field(:updated_at, :naive_datetime, description: "The resource's last update date")
    field(:type, :string, description: "The resource's type (if it's a folder)")
    field(:path, :string, description: "The resource's path")

    field(:parent, :resource, description: "The resource's parent", resolve: dataloader(Resources))

    field :children, :paginated_resource_list do
      description("Children resources in folder")
      resolve(&Resource.find_resources_for_parent/3)
    end
  end

  object :paginated_resource_list do
    field(:elements, list_of(:resource), description: "A list of resources")
    field(:total, :integer, description: "The total number of resources in the list")
  end

  object :resource_metadata do
    field(:type, :string, description: "The type of the resource")
    field(:title, :string, description: "The resource's metadata title")
    field(:description, :string, description: "The resource's metadata description")
    field(:image_remote_url, :string, description: "The resource's metadata image")
    field(:width, :integer)
    field(:height, :integer)
    field(:author_name, :string)
    field(:author_url, :string)
    field(:provider_name, :string)
    field(:provider_url, :string)
    field(:html, :string)
    field(:favicon_url, :string)
  end

  object :resource_queries do
    @desc "Get a resource"
    field :resource, :resource do
      arg(:path, non_null(:string))
      arg(:username, non_null(:string))
      resolve(&Resource.get_resource/3)
    end
  end

  object :resource_mutations do
    @desc "Create a resource"
    field :create_resource, :resource do
      arg(:parent_id, :id)
      arg(:actor_id, non_null(:id))
      arg(:title, non_null(:string))
      arg(:summary, :string)
      arg(:resource_url, :string)
      arg(:type, :string, default_value: "link")

      resolve(&Resource.create_resource/3)
    end

    @desc "Update a resource"
    field :update_resource, :resource do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:summary, :string)
      arg(:parent_id, :id)
      arg(:resource_url, :string)

      resolve(&Resource.update_resource/3)
    end

    @desc "Delete a resource"
    field :delete_resource, :deleted_object do
      arg(:id, non_null(:id))
      resolve(&Resource.delete_resource/3)
    end

    @desc "Get a preview for a resource link"
    field :preview_resource_link, :resource_metadata do
      arg(:resource_url, non_null(:string))
      resolve(&Resource.preview_resource_link/3)
    end
  end
end
