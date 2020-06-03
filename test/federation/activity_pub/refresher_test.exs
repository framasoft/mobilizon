defmodule Mobilizon.Federation.ActivityPub.RefresherTest do
  use Mobilizon.DataCase

  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Refresher
  alias Mobilizon.Web.ActivityPub.ActorView
  import Mobilizon.Factory
  import Mock

  test "refreshes a members collection" do
    %Actor{members_url: members_url, url: group_url} = group = insert(:group)
    %Actor{url: actor_url} = actor = insert(:actor)
    %Member{} = insert(:member, parent: group, actor: actor, role: :member)

    data =
      ActorView.render("members.json", %{group: group, actor_applicant: actor}) |> Jason.encode!()

    with_mocks([
      {HTTPoison, [],
       [
         get!: fn ^members_url, _headers, _options ->
           %HTTPoison.Response{status_code: 200, body: data}
         end
       ]},
      {ActivityPub, [],
       [
         get_or_fetch_actor_by_url: fn url ->
           case url do
             ^actor_url -> {:ok, actor}
             ^group_url -> {:ok, group}
           end
         end
       ]}
    ]) do
      assert :ok == Refresher.fetch_collection(group.members_url, actor)
    end
  end
end
