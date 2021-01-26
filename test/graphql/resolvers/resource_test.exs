defmodule Mobilizon.GraphQL.Resolvers.ResourceTest do
  use Mobilizon.Web.ConnCase

  import Mobilizon.Factory

  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Users.User
  alias Mobilizon.Web.MediaProxy

  alias Mobilizon.GraphQL.AbsintheHelpers

  @metadata_fragment """
  fragment ResourceMetadataBasicFields on ResourceMetadata {
    imageRemoteUrl,
    height,
    width,
    type,
    faviconUrl
  }
  """

  @get_group_resources """
  query($name: String!) {
    group(preferredUsername: $name) {
        id,
        url,
        name,
        domain,
        summary,
        preferredUsername,
        resources(page: 1, limit: 3) {
            elements {
                id,
                title,
                resourceUrl,
                summary,
                updatedAt,
                type,
                path,
                metadata {
                    ...ResourceMetadataBasicFields
                }
            },
            total
        },
    }
  }
  #{@metadata_fragment}
  """

  @get_resource """
  query GetResource($path: String, $username: String) {
    resource(path: $path, username: $username) {
        id,
        title,
        summary,
        url,
        path,
        type,
        metadata {
            ...ResourceMetadataBasicFields
            authorName,
            authorUrl,
            providerName,
            providerUrl,
            html
        },
        parent {
            id
        },
        actor {
            id,
            preferredUsername
        },
        children {
            total,
            elements {
                id,
                title,
                summary,
                url,
                type,
                path,
                resourceUrl,
                metadata {
                    ...ResourceMetadataBasicFields
                }
            }
        }
    }
  }
  #{@metadata_fragment}
  """

  @create_resource """
  mutation CreateResource($title: String!, $parentId: ID, $summary: String, $actorId: ID!, $resourceUrl: String, $type: String) {
    createResource(title: $title, parentId: $parentId, summary: $summary, actorId: $actorId, resourceUrl: $resourceUrl, type: $type) {
        id,
        title,
        summary,
        url,
        resourceUrl,
        updatedAt,
        path,
        type,
        metadata {
            ...ResourceMetadataBasicFields
            authorName,
            authorUrl,
            providerName,
            providerUrl,
            html
        }
    }
  }
  #{@metadata_fragment}
  """

  @update_resource """
  mutation UpdateResource($id: ID!, $title: String, $summary: String, $parentId: ID, $resourceUrl: String) {
    updateResource(id: $id, title: $title, parentId: $parentId, summary: $summary, resourceUrl: $resourceUrl) {
        id,
        title,
        summary,
        url,
        path,
        resourceUrl,
        type,
        children {
          total,
          elements {
              id,
              title,
              summary,
              url,
              type,
              path,
              resourceUrl,
              metadata {
                  ...ResourceMetadataBasicFields
              }
          }
      }
    }
  }
  #{@metadata_fragment}
  """

  @delete_resource """
  mutation DeleteResource($id: ID!) {
    deleteResource(id: $id) {
        id
    }
  }
  """

  @resource_url "https://joinmobilizon.org"
  @resource_title "my resource"
  @updated_resource_title "my updated resource"
  @folder_title "my folder"

  setup do
    %User{} = user = insert(:user)
    %Actor{} = actor = insert(:actor, user: user)
    %Actor{} = group = insert(:group)
    %Member{} = insert(:member, parent: group, actor: actor, role: :member)
    resource_in_root = %Resource{} = insert(:resource, actor: group)

    folder_in_root =
      %Resource{id: parent_id, path: parent_path} =
      insert(:resource,
        type: :folder,
        resource_url: nil,
        actor: group,
        title: "root folder",
        path: "/root folder"
      )

    resource_in_folder =
      %Resource{} =
      insert(:resource,
        resource_url: nil,
        actor: group,
        parent_id: parent_id,
        path: "#{parent_path}/titre",
        title: "titre"
      )

    {:ok,
     user: user,
     group: group,
     root_resources: [folder_in_root, resource_in_root],
     resource_in_folder: resource_in_folder}
  end

  describe "Resolver: Get group's resources" do
    test "find_resources_for_group/3", %{
      conn: conn,
      user: user,
      group: group,
      root_resources: root_resources,
      resource_in_folder: resource_in_folder
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @get_group_resources,
          variables: %{
            name: group.preferred_username
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["group"]["resources"]["total"] == 3

      assert res["data"]["group"]["resources"]["elements"]
             |> Enum.map(&{&1["path"], &1["type"]})
             |> MapSet.new() ==
               (root_resources ++ [resource_in_folder])
               |> Enum.map(&{&1.path, Atom.to_string(&1.type)})
               |> MapSet.new()
    end

    test "find_resources_for_group/3 when not member of group", %{
      conn: conn,
      group: group
    } do
      %User{} = user = insert(:user)
      %Actor{} = insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @get_group_resources,
          variables: %{
            name: group.preferred_username
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["group"]["resources"]["total"] == 0
      assert res["data"]["group"]["resources"]["elements"] == []
    end

    test "find_resources_for_group/3 when not connected", %{
      conn: conn,
      group: group
    } do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @get_group_resources,
          variables: %{
            name: group.preferred_username
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["group"]["resources"]["total"] == 0
      assert res["data"]["group"]["resources"]["elements"] == []
    end
  end

  describe "Resolver: Get a specific resource" do
    test "get_resource/3 for the root path", %{
      conn: conn,
      user: user,
      group: group,
      root_resources: root_resources
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @get_resource,
          variables: %{
            path: "/",
            username: group.preferred_username
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["resource"]["path"] == "/"
      assert String.starts_with?(res["data"]["resource"]["id"], "root_")

      assert res["data"]["resource"]["children"]["elements"]
             |> Enum.map(& &1["id"])
             |> MapSet.new() == root_resources |> Enum.map(& &1.id) |> MapSet.new()
    end

    test "get_resource/3 for a folder path", %{
      conn: conn,
      user: user,
      group: group,
      root_resources: [root_folder, _],
      resource_in_folder: resource_in_folder
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @get_resource,
          variables: %{
            path: root_folder.path,
            username: group.preferred_username
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["resource"]["type"] == "folder"
      assert res["data"]["resource"]["path"] == root_folder.path
      assert is_nil(res["data"]["resource"]["parent"]["id"])

      assert res["data"]["resource"]["children"]["total"] == 1

      assert res["data"]["resource"]["children"]["elements"]
             |> Enum.map(& &1["id"])
             |> MapSet.new() == [resource_in_folder] |> Enum.map(& &1.id) |> MapSet.new()
    end

    test "get_resource/3 for a non-existing path", %{
      conn: conn,
      user: user,
      group: group
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @get_resource,
          variables: %{
            path: "/non existing",
            username: group.preferred_username
          }
        )

      assert hd(res["errors"])["message"] == "Resource not found"
    end

    test "get_resource/3 for a non-existing group", %{
      conn: conn,
      user: user
    } do
      %Actor{preferred_username: group_name} = insert(:group)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @get_resource,
          variables: %{
            path: "/non existing",
            username: group_name
          }
        )

      assert hd(res["errors"])["message"] == "Profile is not member of group"
    end

    test "get_resource/3 when not connected", %{
      conn: conn,
      group: group,
      resource_in_folder: resource_in_folder
    } do
      res =
        conn
        |> AbsintheHelpers.graphql_query(
          query: @get_resource,
          variables: %{
            path: resource_in_folder.path,
            username: group.preferred_username
          }
        )

      assert hd(res["errors"])["message"] == "You need to be logged-in to access resources"
    end
  end

  describe "Resolver: Create a resource" do
    test "create_resource/3 creates a resource for a group", %{
      conn: conn,
      user: user,
      group: group
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_resource,
          variables: %{
            title: @resource_title,
            parentId: nil,
            actorId: group.id,
            resourceUrl: @resource_url
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["createResource"]["metadata"]["faviconUrl"] ==
               MediaProxy.url("https://joinmobilizon.org/img/icons/favicon.png")

      assert res["data"]["createResource"]["metadata"]["imageRemoteUrl"] ==
               MediaProxy.url("https://joinmobilizon.org/img/opengraph/home.jpg")

      assert res["data"]["createResource"]["path"] == "/#{@resource_title}"
      assert res["data"]["createResource"]["resourceUrl"] == @resource_url
      assert res["data"]["createResource"]["title"] == @resource_title
      assert res["data"]["createResource"]["type"] == "link"
    end

    test "create_resource/3 creates a folder", %{conn: conn, user: user, group: group} do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_resource,
          variables: %{
            title: @folder_title,
            parentId: nil,
            actorId: group.id,
            type: "folder"
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["createResource"]["path"] == "/#{@folder_title}"
      assert res["data"]["createResource"]["title"] == @folder_title
      assert res["data"]["createResource"]["type"] == "folder"
    end

    test "create_resource/3 creates a resource in a folder", %{
      conn: conn,
      user: user,
      group: group
    } do
      %Resource{id: parent_id, path: parent_path} =
        insert(:resource, type: :folder, resource_url: nil, actor: group)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_resource,
          variables: %{
            title: @resource_title,
            parentId: parent_id,
            actorId: group.id,
            resourceUrl: @resource_url
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["createResource"]["metadata"]["faviconUrl"] ==
               MediaProxy.url("https://joinmobilizon.org/img/icons/favicon.png")

      assert res["data"]["createResource"]["metadata"]["imageRemoteUrl"] ==
               MediaProxy.url("https://joinmobilizon.org/img/opengraph/home.jpg")

      assert res["data"]["createResource"]["path"] == "#{parent_path}/#{@resource_title}"
      assert res["data"]["createResource"]["resourceUrl"] == @resource_url
      assert res["data"]["createResource"]["title"] == @resource_title
      assert res["data"]["createResource"]["type"] == "link"
    end

    test "create_resource/3 doesn't create a resource in a folder if no group is defined", %{
      conn: conn,
      user: user
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_resource,
          variables: %{
            title: @resource_title,
            parentId: nil,
            resourceUrl: @resource_url
          }
        )

      assert Enum.map(res["errors"], & &1["message"]) == [
               "In argument \"actorId\": Expected type \"ID!\", found null.",
               "Variable \"actorId\": Expected non-null, found null."
             ]
    end

    test "create_resource/3 doesn't create a resource if the actor is not a member of the group",
         %{
           conn: conn,
           group: group
         } do
      %User{} = user = insert(:user)
      %Actor{} = insert(:actor, user: user)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_resource,
          variables: %{
            title: @resource_title,
            parentId: nil,
            actorId: group.id,
            resourceUrl: @resource_url
          }
        )

      assert Enum.map(res["errors"], & &1["message"]) == [
               "Profile is not member of group"
             ]
    end

    test "create_resource/3 doesn't create a resource if the referenced parent folder is not owned by the group",
         %{
           conn: conn,
           user: user,
           group: group
         } do
      %Actor{} = group2 = insert(:group)

      %Resource{id: parent_id} =
        insert(:resource, type: :folder, resource_url: nil, actor: group2)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @create_resource,
          variables: %{
            title: @resource_title,
            parentId: parent_id,
            actorId: group.id,
            resourceUrl: @resource_url
          }
        )

      assert Enum.map(res["errors"], & &1["message"]) == [
               "Parent resource doesn't belong to this group"
             ]
    end
  end

  describe "Resolver: Update a resource" do
    test "update_resource/3 renames a resource for a group", %{
      conn: conn,
      user: user,
      group: group
    } do
      %Resource{id: resource_id} = insert(:resource, resource_url: @resource_url, actor: group)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_resource,
          variables: %{
            id: resource_id,
            title: @updated_resource_title
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["updateResource"]["path"] == "/#{@updated_resource_title}"
      assert res["data"]["updateResource"]["resourceUrl"] == @resource_url
      assert res["data"]["updateResource"]["title"] == @updated_resource_title
      assert res["data"]["updateResource"]["type"] == "link"
    end

    test "update_resource/3 moves and renames a resource for a group", %{
      conn: conn,
      user: user,
      group: group,
      root_resources: [root_folder, _]
    } do
      %Resource{id: resource_id} = insert(:resource, resource_url: @resource_url, actor: group)

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_resource,
          variables: %{
            id: resource_id,
            title: @updated_resource_title,
            parentId: root_folder.id
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["updateResource"]["path"] ==
               "#{root_folder.path}/#{@updated_resource_title}"

      assert res["data"]["updateResource"]["resourceUrl"] == @resource_url
      assert res["data"]["updateResource"]["title"] == @updated_resource_title
      assert res["data"]["updateResource"]["type"] == "link"
    end

    test "update_resource/3 moves a resource in a subfolder for a group", %{
      conn: conn,
      user: user,
      group: group,
      root_resources: [root_folder, _]
    } do
      %Resource{id: resource_id} =
        resource = insert(:resource, resource_url: @resource_url, actor: group)

      folder =
        insert(:resource,
          parent_id: root_folder.id,
          actor: group,
          path: "#{root_folder.path}/subfolder",
          title: "subfolder"
        )

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_resource,
          variables: %{
            id: resource_id,
            parentId: folder.id
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["updateResource"]["path"] ==
               "#{folder.path}/#{resource.title}"

      assert res["data"]["updateResource"]["resourceUrl"] == @resource_url
      assert res["data"]["updateResource"]["title"] == resource.title
      assert res["data"]["updateResource"]["type"] == "link"
    end

    test "update_resource/3 renames a folder and all the paths for it's children", %{
      conn: conn,
      user: user,
      group: group,
      root_resources: [root_folder, _]
    } do
      folder =
        insert(:resource,
          parent_id: root_folder.id,
          actor: group,
          path: "#{root_folder.path}/subfolder",
          title: "subfolder",
          type: :folder
        )

      %Resource{} =
        insert(:resource,
          resource_url: @resource_url,
          actor: group,
          parent_id: folder.id,
          path: "#{folder.path}/titre",
          title: "titre"
        )

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_resource,
          variables: %{
            id: folder.id,
            title: "updated subfolder"
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["updateResource"]["path"] ==
               "#{root_folder.path}/updated subfolder"

      assert res["data"]["updateResource"]["title"] == "updated subfolder"
      assert res["data"]["updateResource"]["type"] == "folder"

      assert hd(res["data"]["updateResource"]["children"]["elements"])["path"] ==
               "#{root_folder.path}/updated subfolder/titre"
    end

    test "update_resource/3 moves a folder and updates all the paths for it's children", %{
      conn: conn,
      user: user,
      group: group,
      root_resources: [root_folder, _]
    } do
      folder =
        insert(:resource,
          parent_id: nil,
          actor: group,
          path: "/subfolder",
          title: "subfolder",
          type: :folder
        )

      %Resource{} =
        insert(:resource,
          resource_url: @resource_url,
          actor: group,
          parent_id: folder.id,
          path: "#{folder.path}/titre",
          title: "titre"
        )

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @update_resource,
          variables: %{
            id: folder.id,
            parentId: root_folder.id,
            title: "updated subfolder"
          }
        )

      assert is_nil(res["errors"])

      assert res["data"]["updateResource"]["path"] ==
               "#{root_folder.path}/updated subfolder"

      assert res["data"]["updateResource"]["title"] == "updated subfolder"
      assert res["data"]["updateResource"]["type"] == "folder"

      assert hd(res["data"]["updateResource"]["children"]["elements"])["path"] ==
               "#{root_folder.path}/updated subfolder/titre"
    end
  end

  describe "Resolver: Delete a resource" do
    test "delete_resource/3 deletes a resource", %{
      conn: conn,
      user: user,
      group: group
    } do
      %Resource{id: resource_id, path: resource_path} =
        insert(:resource,
          resource_url: @resource_url,
          actor: group,
          parent_id: nil
        )

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_resource,
          variables: %{
            id: resource_id
          }
        )

      assert is_nil(res["errors"])
      assert res["data"]["deleteResource"]["id"] == resource_id

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @get_resource,
          variables: %{
            path: resource_path,
            username: group.preferred_username
          }
        )

      assert hd(res["errors"])["message"] == "Resource not found"
    end

    test "delete_resource/3 deletes a folder and children", %{
      conn: conn,
      user: user,
      group: group
    } do
      %Resource{id: folder_id, path: folder_path} =
        insert(:resource,
          parent_id: nil,
          actor: group,
          path: "/subfolder",
          title: "subfolder",
          type: :folder
        )

      %Resource{path: resource_path} =
        insert(:resource,
          resource_url: @resource_url,
          actor: group,
          parent_id: folder_id,
          path: "#{folder_path}/titre",
          title: "titre"
        )

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_resource,
          variables: %{
            id: folder_id
          }
        )

      assert is_nil(res["errors"])
      assert res["data"]["deleteResource"]["id"] == folder_id

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @get_resource,
          variables: %{
            path: folder_path,
            username: group.preferred_username
          }
        )

      assert hd(res["errors"])["message"] == "Resource not found"

      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @get_resource,
          variables: %{
            path: resource_path,
            username: group.preferred_username
          }
        )

      assert hd(res["errors"])["message"] == "Resource not found"
    end

    test "delete_resource/3 deletes a resource not found", %{
      conn: conn,
      user: user
    } do
      res =
        conn
        |> auth_conn(user)
        |> AbsintheHelpers.graphql_query(
          query: @delete_resource,
          variables: %{
            id: "58869b5b-2beb-423a-b483-1585d847e2cc"
          }
        )

      assert hd(res["errors"])["message"] == "Resource doesn't exist"
    end
  end
end
