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
    interfaces([:activity_object])
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

  @desc """
  A paginated list of resources
  """
  object :paginated_resource_list do
    field(:elements, list_of(:resource), description: "A list of resources")
    field(:total, :integer, description: "The total number of resources in the list")
  end

  @desc """
  The metadata associated to the resource
  """
  object :resource_metadata do
    field(:type, :string, description: "The type of the resource")
    field(:title, :string, description: "The resource's metadata title")
    field(:description, :string, description: "The resource's metadata description")

    field(:image_remote_url, :string,
      description: "The resource's metadata image",
      resolve: &Resource.proxyify_pictures/3
    )

    field(:width, :integer, description: "The resource's metadata image width")
    field(:height, :integer, description: "The resource's metadata image height")
    field(:author_name, :string, description: "The resource's author name")
    field(:author_url, :string, description: "The resource's author URL")
    field(:provider_name, :string, description: "The resource's provider name")
    field(:provider_url, :string, description: "The resource's provider URL")
    field(:html, :string, description: "The resource's author name")

    field(:favicon_url, :string,
      description: "The resource's favicon URL",
      resolve: &Resource.proxyify_pictures/3
    )
  end

  object :resource_queries do
    @desc "Get a resource"
    field :resource, :resource do
      arg(:path, non_null(:string), description: "The path for the resource")

      arg(:username, non_null(:string),
        description: "The federated username for the group resource"
      )

      resolve(&Resource.get_resource/3)
    end
  end

  object :resource_mutations do
    @desc "Create a resource"
    field :create_resource, :resource do
      arg(:parent_id, :id,
        description: "The ID from the parent resource (folder) this resource is in"
      )

      arg(:actor_id, non_null(:id), description: "The group this resource belongs to")
      arg(:title, non_null(:string), description: "This resource's title")
      arg(:summary, :string, description: "This resource summary")
      arg(:resource_url, :string, description: "This resource's own original URL")
      arg(:type, :string, default_value: "link", description: "The type for this resource")

      resolve(&Resource.create_resource/3)
    end

    @desc "Update a resource"
    field :update_resource, :resource do
      arg(:id, non_null(:id), description: "The resource ID")
      arg(:title, :string, description: "The new resource title")
      arg(:summary, :string, description: "The new resource summary")
      arg(:parent_id, :id, description: "The new resource parent ID (if the resource is moved)")
      arg(:resource_url, :string, description: "The new resource URL")

      resolve(&Resource.update_resource/3)
    end

    @desc "Delete a resource"
    field :delete_resource, :deleted_object do
      arg(:id, non_null(:id), description: "The resource ID")
      resolve(&Resource.delete_resource/3)
    end

    @desc "Get a preview for a resource link"
    field :preview_resource_link, :resource_metadata do
      arg(:resource_url, non_null(:string), description: "The link to crawl to get of preview of")
      resolve(&Resource.preview_resource_link/3)
    end
  end
end
