defmodule MobilizonWeb.Schema.Actors.PersonType do
  @moduledoc """
  Schema representation for Person
  """
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import_types(MobilizonWeb.Schema.UserType)
  alias Mobilizon.Events

  @desc """
  Represents a person identity
  """
  object :person do
    interfaces([:actor])
    field(:id, :id, description: "Internal ID for this person")
    field(:user, :user, description: "The user this actor is associated to")

    field(:member_of, list_of(:member), description: "The list of groups this person is member of")

    field(:url, :string, description: "The ActivityPub actor's URL")
    field(:type, :actor_type, description: "The type of Actor (Person, Group,…)")
    field(:name, :string, description: "The actor's displayed name")
    field(:domain, :string, description: "The actor's domain if (null if it's this instance)")
    field(:local, :boolean, description: "If the actor is from this instance")
    field(:summary, :string, description: "The actor's summary")
    field(:preferred_username, :string, description: "The actor's preferred username")
    field(:keys, :string, description: "The actors RSA Keys")

    field(:manually_approves_followers, :boolean,
      description: "Whether the actors manually approves followers"
    )

    field(:suspended, :boolean, description: "If the actor is suspended")
    field(:avatar_url, :string, description: "The actor's avatar url")
    field(:banner_url, :string, description: "The actor's banner url")

    # These one should have a privacy setting
    field(:following, list_of(:follower), description: "List of followings")
    field(:followers, list_of(:follower), description: "List of followers")
    field(:followersCount, :integer, description: "Number of followers for this actor")
    field(:followingCount, :integer, description: "Number of actors following this actor")

    # This one should have a privacy setting
    field(:organized_events, list_of(:event),
      resolve: dataloader(Events),
      description: "A list of the events this actor has organized"
    )
  end
end
