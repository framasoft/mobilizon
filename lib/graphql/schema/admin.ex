defmodule Mobilizon.GraphQL.Schema.AdminType do
  @moduledoc """
  Schema representation for ActionLog.
  """

  use Absinthe.Schema.Notation

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Reports.{Note, Report}
  alias Mobilizon.Users.User

  alias Mobilizon.GraphQL.Resolvers.Admin

  @desc "An action log"
  object :action_log do
    meta(:authorize, :moderator)
    field(:id, :id, description: "Internal ID for this comment")
    field(:actor, :actor, description: "The actor that acted")
    field(:object, :action_log_object, description: "The object that was acted upon")
    field(:action, :action_log_action, description: "The action that was done")
    field(:inserted_at, :datetime, description: "The time when the action was performed")
  end

  @desc """
  A paginated list of action logs
  """
  object :paginated_action_log_list do
    meta(:authorize, :moderator)
    field(:elements, list_of(:action_log), description: "A list of action logs")
    field(:total, :integer, description: "The total number of action logs in the list")
  end

  @desc """
  The different types of action log actions
  """
  enum :action_log_action do
    value(:report_update_closed, description: "The report was closed")
    value(:report_update_opened, description: "The report was opened")
    value(:report_update_resolved, description: "The report was resolved")
    value(:note_creation, description: "A note was created on a report")
    value(:note_deletion, description: "A note was deleted on a report")
    value(:event_deletion, description: "An event was deleted")
    value(:comment_deletion, description: "A comment was deleted")
    value(:event_update, description: "An event was updated")
    value(:actor_suspension, description: "An actor was suspended")
    value(:actor_unsuspension, description: "An actor was unsuspended")
    value(:user_deletion, description: "An user was deleted")
  end

  @desc "The objects that can be in an action log"
  interface :action_log_object do
    meta(:authorize, [:moderator, :administrator])
    field(:id, :id, description: "Internal ID for this object")

    resolve_type(fn
      %Report{}, _ ->
        :report

      %Note{}, _ ->
        :report_note

      %Event{}, _ ->
        :event

      %Comment{}, _ ->
        :comment

      %Actor{type: :Person}, _ ->
        :person

      %User{}, _ ->
        :user

      %Actor{type: :Group}, _ ->
        :group

      _, _ ->
        nil
    end)
  end

  @desc """
  Language information
  """
  object :language do
    meta(:authorize, :all)
    field(:code, :string, description: "The iso-639-3 language code")
    field(:name, :string, description: "The language name")
  end

  @desc """
  Dashboard information
  """
  object :dashboard do
    meta(:authorize, :administrator)
    field(:last_public_event_published, :event, description: "Last public event published")
    field(:last_group_created, :group, description: "Last public group created")
    field(:number_of_users, :integer, description: "The number of local users")
    field(:number_of_events, :integer, description: "The number of local events")
    field(:number_of_comments, :integer, description: "The number of local comments")
    field(:number_of_groups, :integer, description: "The number of local groups")
    field(:number_of_reports, :integer, description: "The number of current opened reports")
    field(:number_of_followers, :integer, description: "The number of instance followers")
    field(:number_of_followings, :integer, description: "The number of instance followings")

    field(:number_of_confirmed_participations_to_local_events, :integer,
      description: "The number of total confirmed participations to local events"
    )
  end

  @desc """
  Admin settings
  """
  object :admin_settings do
    meta(:authorize, :administrator)
    field(:instance_name, :string, description: "The instance's name")
    field(:instance_description, :string, description: "The instance's description")
    field(:instance_long_description, :string, description: "The instance's long description")
    field(:instance_slogan, :string, description: "The instance's slogan")
    field(:contact, :string, description: "The instance's contact details")
    field(:instance_terms, :string, description: "The instance's terms body text")
    field(:instance_terms_type, :instance_terms_type, description: "The instance's terms type")
    field(:instance_terms_url, :string, description: "The instance's terms URL")

    field(:instance_logo, :media,
      description: "The instance's logo",
      resolve: &Admin.get_instance_logo/3
    )

    field(:instance_favicon, :media,
      description: "The instance's favicon",
      resolve: &Admin.get_instance_favicon/3
    )

    field(:default_picture, :media,
      description: "The default picture",
      resolve: &Admin.get_default_picture/3
    )

    field(:primary_color, :string, description: "The instance's primary color")
    field(:secondary_color, :string, description: "The instance's secondary color")

    field(:instance_privacy_policy, :string,
      description: "The instance's privacy policy body text"
    )

    field(:instance_privacy_policy_type, :instance_privacy_type,
      description: "The instance's privacy policy type"
    )

    field(:instance_privacy_policy_url, :string, description: "The instance's privacy policy URL")
    field(:instance_rules, :string, description: "The instance's rules")
    field(:registrations_open, :boolean, description: "Whether the registrations are opened")
    field(:instance_languages, list_of(:string), description: "The instance's languages")
  end

  @desc "The acceptable values for the instance's terms type"
  enum :instance_terms_type do
    value(:url, as: "URL", description: "An URL. Users will be redirected to this URL.")
    value(:default, as: "DEFAULT", description: "Terms will be set to Mobilizon's default terms")
    value(:custom, as: "CUSTOM", description: "Custom terms text")
  end

  @desc """
  The acceptable values for the instance privacy policy type
  """
  enum :instance_privacy_type do
    value(:url, as: "URL", description: "An URL. Users will be redirected to this URL.")

    value(:default,
      as: "DEFAULT",
      description: "Privacy policy will be set to Mobilizon's default privacy policy"
    )

    value(:custom, as: "CUSTOM", description: "Custom privacy policy text")
  end

  enum :instance_follow_status do
    value(:approved, description: "The instance follow was approved")
    value(:pending, description: "The instance follow is still pending")
    value(:none, description: "There's no instance follow etablished")
  end

  enum :instances_sort_fields do
    value(:event_count)
    value(:person_count)
    value(:group_count)
    value(:followers_count)
    value(:followings_count)
    value(:reports_count)
    value(:media_size)
  end

  enum :instance_filter_follow_status do
    value(:all)
    value(:following)
    value(:followed)
  end

  enum :instance_filter_suspend_status do
    value(:all)
    value(:suspended)
  end

  @desc """
  An instance representation
  """
  object :instance do
    meta(:authorize, :administrator)
    field(:domain, :id, description: "The domain name of the instance")
    field(:follower_status, :instance_follow_status, description: "Do we follow this instance")
    field(:followed_status, :instance_follow_status, description: "Does this instance follow us?")

    field(:event_count, :integer, description: "The number of events on this instance we know of")

    field(:person_count, :integer,
      description: "The number of profiles on this instance we know of"
    )

    field(:group_count, :integer, description: "The number of grouo on this instance we know of")

    field(:followers_count, :integer,
      description: "The number of their profiles who follow our groups"
    )

    field(:followings_count, :integer,
      description: "The number of our profiles who follow their groups"
    )

    field(:reports_count, :integer,
      description: "The number of reports made against profiles from this instance"
    )

    field(:media_size, :integer,
      description: "The size of all the media files sent by actors from this instance"
    )

    field(:has_relay, :boolean,
      description:
        "Whether this instance has a relay, meaning that it's a Mobilizon instance that we can follow"
    )

    field(:relay_address, :string,
      description: "If this instance has a relay, it's federated username"
    )

    field(:instance_name, :string, description: "This instance's name")

    field(:instance_description, :string, description: "This instance's description")

    field(:software, :string, description: "The software this instance declares running")

    field(:software_version, :string,
      description: "The software version this instance declares running"
    )
  end

  @desc """
  A paginated list of instances
  """
  object :paginated_instance_list do
    meta(:authorize, :administrator)
    field(:elements, list_of(:instance), description: "A list of instances")
    field(:total, :integer, description: "The total number of instances in the list")
  end

  object :admin_queries do
    @desc "Get the list of action logs"
    field :action_logs, type: :paginated_action_log_list do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      middleware(Rajska.QueryAuthorization, permit: :moderator, scope: false)
      resolve(&Admin.list_action_logs/3)
    end

    @desc """
    List the instance's supported languages
    """
    field :languages, type: list_of(:language) do
      arg(:codes, list_of(:string),
        description:
          "The user's locale. The list of languages will be translated with this locale"
      )

      middleware(Rajska.QueryAuthorization, permit: :all)
      resolve(&Admin.get_list_of_languages/3)
    end

    @desc """
    Get dashboard information
    """
    field :dashboard, type: :dashboard do
      middleware(Rajska.QueryAuthorization, permit: :administrator)
      resolve(&Admin.get_dashboard/3)
    end

    @desc """
    Get admin settings
    """
    field :admin_settings, type: :admin_settings do
      middleware(Rajska.QueryAuthorization, permit: :administrator)
      resolve(&Admin.get_settings/3)
    end

    @desc """
    List the relay followers
    """
    field :relay_followers, type: :paginated_follower_list do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated relay followers list"
      )

      arg(:limit, :integer,
        default_value: 10,
        description: "The limit of relay followers per page"
      )

      middleware(Rajska.QueryAuthorization, permit: :administrator)
      resolve(&Admin.list_relay_followers/3)
    end

    @desc """
    List the relay followings
    """
    field :relay_followings, type: :paginated_follower_list do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated relay followings list"
      )

      arg(:limit, :integer,
        default_value: 10,
        description: "The limit of relay followings per page"
      )

      arg(:order_by, :string,
        default_value: :updated_at,
        description: "The field to order by the list"
      )

      arg(:direction, :string, default_value: :desc, description: "The sorting direction")
      middleware(Rajska.QueryAuthorization, permit: :administrator)
      resolve(&Admin.list_relay_followings/3)
    end

    @desc """
    List instances
    """
    field :instances, :paginated_instance_list do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated relay followings list"
      )

      arg(:limit, :integer,
        default_value: 10,
        description: "The limit of relay followings per page"
      )

      arg(:order_by, :instances_sort_fields,
        default_value: :event_count,
        description: "The field to order by the list"
      )

      arg(:filter_domain, :string, default_value: nil, description: "Filter by domain")

      arg(:filter_follow_status, :instance_filter_follow_status,
        default_value: :all,
        description: "Whether or not to filter instances by the follow status"
      )

      arg(:filter_suspend_status, :instance_filter_suspend_status,
        default_value: :all,
        description: "Whether or not to filter instances by the suspended status"
      )

      arg(:direction, :string, default_value: :desc, description: "The sorting direction")
      middleware(Rajska.QueryAuthorization, permit: :administrator)
      resolve(&Admin.get_instances/3)
    end

    @desc """
    Get an instance's details
    """
    field :instance, :instance do
      arg(:domain, non_null(:id), description: "The instance domain")
      middleware(Rajska.QueryAuthorization, permit: :administrator)
      resolve(&Admin.get_instance/3)
    end
  end

  object :admin_mutations do
    @desc "Add an instance subscription"
    field :add_instance, type: :instance do
      arg(:domain, non_null(:string), description: "The instance domain to add")
      middleware(Rajska.QueryAuthorization, permit: :administrator)
      resolve(&Admin.create_instance/3)
    end

    @desc "Delete a relay subscription"
    field :remove_relay, type: :follower do
      arg(:address, non_null(:string), description: "The relay hostname to delete")
      middleware(Rajska.QueryAuthorization, permit: :administrator)
      resolve(&Admin.remove_relay/3)
    end

    @desc "Accept a relay subscription"
    field :accept_relay, type: :follower do
      arg(:address, non_null(:string), description: "The accepted relay hostname")
      middleware(Rajska.QueryAuthorization, permit: :administrator)
      resolve(&Admin.accept_subscription/3)
    end

    @desc "Reject a relay subscription"
    field :reject_relay, type: :follower do
      arg(:address, non_null(:string), description: "The rejected relay hostname")
      middleware(Rajska.QueryAuthorization, permit: :administrator)
      resolve(&Admin.reject_subscription/3)
    end

    @desc """
    Save admin settings
    """
    field :save_admin_settings, type: :admin_settings do
      arg(:instance_name, :string, description: "The instance's name")
      arg(:instance_description, :string, description: "The instance's description")
      arg(:instance_long_description, :string, description: "The instance's long description")
      arg(:instance_slogan, :string, description: "The instance's slogan")
      arg(:contact, :string, description: "The instance's contact details")

      arg(:instance_logo, :media_input,
        description:
          "The instance's logo, either as an object or directly the ID of an existing media"
      )

      arg(:instance_favicon, :media_input,
        description:
          "The instance's favicon, either as an object or directly the ID of an existing media"
      )

      arg(:default_picture, :media_input,
        description:
          "The default picture, either as an object or directly the ID of an existing media"
      )

      arg(:primary_color, :string, description: "The instance's primary color")
      arg(:secondary_color, :string, description: "The instance's secondary color")

      arg(:instance_terms, :string, description: "The instance's terms body text")
      arg(:instance_terms_type, :instance_terms_type, description: "The instance's terms type")
      arg(:instance_terms_url, :string, description: "The instance's terms URL")

      arg(:instance_privacy_policy, :string,
        description: "The instance's privacy policy body text"
      )

      arg(:instance_privacy_policy_type, :instance_privacy_type,
        description: "The instance's privacy policy type"
      )

      arg(:instance_privacy_policy_url, :string, description: "The instance's privacy policy URL")
      arg(:instance_rules, :string, description: "The instance's rules")
      arg(:registrations_open, :boolean, description: "Whether the registrations are opened")
      arg(:instance_languages, list_of(:string), description: "The instance's languages")
      middleware(Rajska.QueryAuthorization, permit: :administrator)
      resolve(&Admin.save_settings/3)
    end

    @desc """
    For an admin to update an user
    """
    field :admin_update_user, type: :user do
      arg(:id, non_null(:id), description: "The user's ID")
      arg(:email, :string, description: "The user's new email")
      arg(:confirmed, :boolean, description: "Manually confirm the user's account")
      arg(:role, :user_role, description: "Set user's new role")

      arg(:notify, :boolean,
        default_value: false,
        description: "Whether or not to notify the user of the change"
      )

      middleware(Rajska.QueryAuthorization, permit: :administrator)
      resolve(&Admin.update_user/3)
    end
  end
end
