defmodule Mobilizon.GraphQL.Schema.Actors.PersonType do
  @moduledoc """
  Schema representation for Person
  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Mobilizon.Events
  alias Mobilizon.GraphQL.Resolvers.{Media, Person}
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

    field(:avatar, :media, description: "The actor's avatar media")
    field(:banner, :media, description: "The actor's banner media")

    # These one should have a privacy setting
    field(:followersCount, :integer, description: "Number of followers for this actor")
    field(:followingCount, :integer, description: "Number of actors following this actor")

    field(:media_size, :integer,
      resolve: &Media.actor_size/3,
      description: "The total size of the media from this actor"
    )

    field(:feed_tokens, list_of(:feed_token),
      resolve: dataloader(Events),
      description: "A list of the feed tokens for this person"
    )

    # This one should have a privacy setting
    field(:organized_events, :paginated_event_list,
      description: "A list of the events this actor has organized"
    ) do
      arg(:page, :integer, default_value: 1, description: "The page in the paginated event list")
      arg(:limit, :integer, default_value: 10, description: "The limit of events per page")
      resolve(&Person.organized_events_for_person/3)
    end

    @desc "The list of events this person goes to"
    field(:participations, :paginated_participant_list,
      description: "The list of events this person goes to"
    ) do
      arg(:event_id, :id)

      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated participation list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of participations per page")

      resolve(&Person.person_participations/3)
    end

    @desc "The list of group this person is member of"
    field(:memberships, :paginated_member_list,
      description: "The list of group this person is member of"
    ) do
      resolve(&Person.person_memberships/3)
    end
  end

  @desc """
  A paginated list of persons
  """
  object :paginated_person_list do
    field(:elements, list_of(:person), description: "A list of persons")
    field(:total, :integer, description: "The total number of persons in the list")
  end

  object :person_queries do
    @desc "Get the current actor for the logged-in user"
    field :logged_person, :person do
      resolve(&Person.get_current_person/3)
    end

    @desc "Get a person by its (federated) username"
    field :fetch_person, :person do
      arg(:preferred_username, non_null(:string), description: "The person's federated username")
      resolve(&Person.fetch_person/3)
    end

    @desc "Get a person by its ID"
    field :person, :person do
      arg(:id, non_null(:id), description: "The person ID")
      resolve(&Person.get_person/3)
    end

    @desc "Get the persons for an user"
    field :identities, list_of(:person) do
      resolve(&Person.identities/3)
    end

    @desc "List the profiles"
    field :persons, :paginated_person_list do
      arg(:preferred_username, :string, default_value: "", description: "Filter by username")
      arg(:name, :string, default_value: "", description: "Filter by name")
      arg(:domain, :string, default_value: "", description: "Filter by domain")

      arg(:local, :boolean,
        default_value: true,
        description: "Filter by profile being local or not"
      )

      arg(:suspended, :boolean, default_value: false, description: "Filter by suspended status")
      arg(:page, :integer, default_value: 1, description: "The page in the paginated person list")
      arg(:limit, :integer, default_value: 10, description: "The limit of persons per page")
      resolve(&Person.list_persons/3)
    end
  end

  object :person_mutations do
    @desc "Create a new person for user"
    field :create_person, :person do
      arg(:preferred_username, non_null(:string), description: "The username for the profile")

      arg(:name, :string, description: "The displayed name for the new profile", default_value: "")

      arg(:summary, :string, description: "The summary for the new profile", default_value: "")

      arg(:avatar, :media_input,
        description:
          "The avatar for the profile, either as an object or directly the ID of an existing media"
      )

      arg(:banner, :media_input,
        description:
          "The banner for the profile, either as an object or directly the ID of an existing media"
      )

      resolve(&Person.create_person/3)
    end

    @desc "Update an identity"
    field :update_person, :person do
      arg(:id, non_null(:id), description: "The person's ID")

      arg(:name, :string, description: "The displayed name for this profile")

      arg(:summary, :string, description: "The summary for this profile")

      arg(:avatar, :media_input,
        description:
          "The avatar for the profile, either as an object or directly the ID of an existing media"
      )

      arg(:banner, :media_input,
        description:
          "The banner for the profile, either as an object or directly the ID of an existing media"
      )

      resolve(&Person.update_person/3)
    end

    @desc "Delete an identity"
    field :delete_person, :person do
      arg(:id, non_null(:id), description: "The person's ID")

      resolve(&Person.delete_person/3)
    end

    @desc "Register a first profile on registration"
    field :register_person, :person do
      arg(:preferred_username, non_null(:string), description: "The username for the profile")

      arg(:name, :string, description: "The displayed name for the new profile", default_value: "")

      arg(:summary, :string, description: "The summary for the new profile", default_value: "")
      arg(:email, non_null(:string), description: "The email from the user previously created")

      arg(:avatar, :media_input,
        description:
          "The avatar for the profile, either as an object or directly the ID of an existing media"
      )

      arg(:banner, :media_input,
        description:
          "The banner for the profile, either as an object or directly the ID of an existing media"
      )

      resolve(&Person.register_person/3)
    end
  end

  object :person_subscriptions do
    @desc "Notify when a person's participation's status changed for an event"
    field :event_person_participation_changed, :person do
      arg(:person_id, non_null(:id), description: "The person's ID")

      config(fn args, _ ->
        {:ok, topic: args.person_id}
      end)
    end

    @desc "Notify when a person's membership's status changed for a group"
    field :group_membership_changed, :person do
      arg(:person_id, non_null(:id), description: "The person's ID")

      config(fn args, _ ->
        {:ok, topic: args.person_id}
      end)
    end
  end
end
