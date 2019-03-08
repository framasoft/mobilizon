defmodule MobilizonWeb.Schema.Actors.PersonType do
  @moduledoc """
  Schema representation for Person
  """
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias Mobilizon.Events
  alias MobilizonWeb.Resolvers
  import MobilizonWeb.Schema.Utils

  import_types(MobilizonWeb.Schema.Events.FeedTokenType)

  @desc """
  Represents a person identity
  """
  object :person do
    interfaces([:actor])
    field(:id, :integer, description: "Internal ID for this person")
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

    field(:feed_tokens, list_of(:feed_token),
      resolve: dataloader(Events),
      description: "A list of the feed tokens for this person"
    )

    # This one should have a privacy setting
    field(:organized_events, list_of(:event),
      resolve: dataloader(Events),
      description: "A list of the events this actor has organized"
    )
  end

  object :person_queries do
    @desc "Get the current actor for the logged-in user"
    field :logged_person, :person do
      resolve(&Resolvers.Person.get_current_person/3)
    end

    @desc "Get a person by it's preferred username"
    field :person, :person do
      arg(:preferred_username, non_null(:string))
      resolve(&Resolvers.Person.find_person/3)
    end

    @desc "Get the persons for an user"
    field :identities, list_of(:person) do
      resolve(&Resolvers.Person.identities/3)
    end
  end

  object :person_mutations do
    @desc "Create a new person for user"
    field :create_person, :person do
      arg(:preferred_username, non_null(:string))

      arg(:name, :string, description: "The displayed name for the new profile", default_value: "")

      arg(:summary, :string, description: "The summary for the new profile", default_value: "")

      resolve(handle_errors(&Resolvers.Person.create_person/3))
    end

    @desc "Register a first profile on registration"
    field :register_person, :person do
      arg(:preferred_username, non_null(:string))

      arg(:name, :string, description: "The displayed name for the new profile", default_value: "")

      arg(:summary, :string, description: "The summary for the new profile", default_value: "")
      arg(:email, non_null(:string), description: "The email from the user previously created")

      resolve(handle_errors(&Resolvers.Person.register_person/3))
    end
  end
end
