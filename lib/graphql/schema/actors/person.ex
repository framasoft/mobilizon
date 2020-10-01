defmodule Mobilizon.GraphQL.Schema.Actors.PersonType do
  @moduledoc """
  Schema representation for Person
  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Mobilizon.Events
  alias Mobilizon.GraphQL.Resolvers.Person
  alias Mobilizon.GraphQL.Schema

  import_types(Schema.Events.FeedTokenType)

  @desc """
  Represents a person identity
  """
  object :person do
    interfaces([:actor, :action_log_object])
    field(:id, :id, description: "Internal ID for this person")

    field(:user, :user,
      description: "The user this actor is associated to",
      resolve: &Person.user_for_person/3
    )

    field(:member_of, list_of(:member), description: "The list of groups this person is member of")

    field(:url, :string, description: "The ActivityPub actor's URL")
    field(:type, :actor_type, description: "The type of Actor (Person, Group,…)")
    field(:name, :string, description: "The actor's displayed name")
    field(:domain, :string, description: "The actor's domain if (null if it's this instance)")
    field(:local, :boolean, description: "If the actor is from this instance")
    field(:summary, :string, description: "The actor's summary")
    field(:preferred_username, :string, description: "The actor's preferred username")

    field(:manually_approves_followers, :boolean,
      description: "Whether the actors manually approves followers"
    )

    field(:suspended, :boolean, description: "If the actor is suspended")

    field(:avatar, :picture, description: "The actor's avatar picture")
    field(:banner, :picture, description: "The actor's banner picture")

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
    field(:organized_events, :paginated_event_list,
      description: "A list of the events this actor has organized"
    ) do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Person.organized_events_for_person/3)
    end

    @desc "The list of events this person goes to"
    field(:participations, :paginated_participant_list,
      description: "The list of events this person goes to"
    ) do
      arg(:event_id, :id)
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Person.person_participations/3)
    end

    @desc "The list of group this person is member of"
    field(:memberships, :paginated_member_list,
      description: "The list of group this person is member of"
    ) do
      resolve(&Person.person_memberships/3)
    end
  end

  object :person_queries do
    @desc "Get the current actor for the logged-in user"
    field :logged_person, :person do
      resolve(&Person.get_current_person/3)
    end

    @desc "Get a person by its (federated) username"
    field :fetch_person, :person do
      arg(:preferred_username, non_null(:string))
      resolve(&Person.fetch_person/3)
    end

    @desc "Get a person by its ID"
    field :person, :person do
      arg(:id, non_null(:id))
      resolve(&Person.get_person/3)
    end

    @desc "Get the persons for an user"
    field :identities, list_of(:person) do
      resolve(&Person.identities/3)
    end

    field :persons, :persons do
      arg(:preferred_username, :string, default_value: "")
      arg(:name, :string, default_value: "")
      arg(:domain, :string, default_value: "")
      arg(:local, :boolean, default_value: true)
      arg(:suspended, :boolean, default_value: false)
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Person.list_persons/3)
    end
  end

  object :person_mutations do
    @desc "Create a new person for user"
    field :create_person, :person do
      arg(:preferred_username, non_null(:string))

      arg(:name, :string, description: "The displayed name for the new profile", default_value: "")

      arg(:summary, :string, description: "The summary for the new profile", default_value: "")

      arg(:avatar, :picture_input,
        description:
          "The avatar for the profile, either as an object or directly the ID of an existing Picture"
      )

      arg(:banner, :picture_input,
        description:
          "The banner for the profile, either as an object or directly the ID of an existing Picture"
      )

      resolve(&Person.create_person/3)
    end

    @desc "Update an identity"
    field :update_person, :person do
      arg(:id, non_null(:id))

      arg(:name, :string, description: "The displayed name for this profile")

      arg(:summary, :string, description: "The summary for this profile")

      arg(:avatar, :picture_input,
        description:
          "The avatar for the profile, either as an object or directly the ID of an existing Picture"
      )

      arg(:banner, :picture_input,
        description:
          "The banner for the profile, either as an object or directly the ID of an existing Picture"
      )

      resolve(&Person.update_person/3)
    end

    @desc "Delete an identity"
    field :delete_person, :person do
      arg(:id, non_null(:id))

      resolve(&Person.delete_person/3)
    end

    @desc "Register a first profile on registration"
    field :register_person, :person do
      arg(:preferred_username, non_null(:string))

      arg(:name, :string, description: "The displayed name for the new profile", default_value: "")

      arg(:summary, :string, description: "The summary for the new profile", default_value: "")
      arg(:email, non_null(:string), description: "The email from the user previously created")

      arg(:avatar, :picture_input,
        description:
          "The avatar for the profile, either as an object or directly the ID of an existing Picture"
      )

      arg(:banner, :picture_input,
        description:
          "The banner for the profile, either as an object or directly the ID of an existing Picture"
      )

      resolve(&Person.register_person/3)
    end
  end

  object :person_subscriptions do
    field :event_person_participation_changed, :person do
      arg(:person_id, non_null(:id))

      config(fn args, _ ->
        {:ok, topic: args.person_id}
      end)
    end
  end
end
