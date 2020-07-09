defmodule Mobilizon.Federation.ActivityPub.RefresherTest do
  use Mobilizon.DataCase

  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Federation.ActivityPub.Refresher
  alias Mobilizon.Service.HTTP.ActivityPub.Mock
  alias Mobilizon.Web.ActivityPub.ActorView
  import Mobilizon.Factory
  import Mox

  describe "refreshes a" do
    setup :verify_on_exit!

    test "members collection" do
      %Actor{members_url: members_url} =
        group =
        insert(:group,
          url: "https://remoteinstance.tld/@group",
          members_url: "https://remoteinstance.tld/@group/members",
          domain: "remoteinstance.tld"
        )

      %Actor{} = actor = insert(:actor)
      %Member{} = insert(:member, parent: group, actor: actor, role: :member)

      data = ActorView.render("members.json", %{actor: group, actor_applicant: actor})

      Mock
      |> expect(:call, fn
        %{method: :get, url: ^members_url}, _opts ->
          {:ok, %Tesla.Env{status: 200, body: data}}
      end)

      assert :ok == Refresher.fetch_collection(group.members_url, actor)
    end
  end
end
