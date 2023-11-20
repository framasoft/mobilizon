defmodule Mobilizon.GraphQL.Schema.UserType do
  @moduledoc """
  Schema representation for User
  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  alias Mobilizon.Events
  alias Mobilizon.GraphQL.Resolvers.Application, as: ApplicationResolver
  alias Mobilizon.GraphQL.Resolvers.{Conversation, Media, User}
  alias Mobilizon.GraphQL.Resolvers.Users.ActivitySettings
  alias Mobilizon.GraphQL.Schema

  import_types(Schema.SortType)

  @env Application.compile_env(:mobilizon, :env)
  @user_ip_limit 10
  @user_email_limit 5

  @desc "A local user of Mobilizon"
  object :user do
    meta(:authorize, :all)
    meta(:scope_field?, true)
    interfaces([:action_log_object])
    field(:id, :id, description: "The user's ID")
    field(:email, non_null(:string), description: "The user's email")

    field(:actors, non_null(list_of(:person)),
      description: "The user's list of profiles (identities)"
    )

    field(:default_actor, :person, description: "The user's default actor")

    field(:confirmed_at, :datetime,
      description: "The datetime when the user was confirmed/activated"
    )

    field(:confirmation_sent_at, :datetime,
      description: "The datetime the last activation/confirmation token was sent"
    )

    field(:confirmation_token, :string, description: "The account activation/confirmation token")

    field(:reset_password_sent_at, :datetime,
      description: "The datetime last reset password email was sent"
    )

    field(:reset_password_token, :string,
      description: "The token sent when requesting password token"
    )

    field(:feed_tokens, list_of(:feed_token),
      resolve:
        dataloader(
          Events,
          callback: fn feed_tokens, _parent, _args ->
            {:ok, Enum.map(feed_tokens, &Map.put(&1, :token, ShortUUID.encode!(&1.token)))}
          end
        ),
      description: "A list of the feed tokens for this user"
    )

    field(:role, :user_role, description: "The role for the user")

    field(:locale, :string, description: "The user's locale")

    field(:provider, :string, description: "The user's login provider")

    field(:disabled, :boolean, description: "Whether the user is disabled")

    field(:participations, :paginated_participant_list,
      description: "The list of participations this user has",
      meta: [private: true, rule: :"read:user:participations"]
    ) do
      arg(:after_datetime, :datetime,
        description: "Filter participations by event start datetime"
      )

      arg(:before_datetime, :datetime, description: "Filter participations by event end datetime")

      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated participations list"
      )

      arg(:limit, :integer,
        default_value: 10,
        description: "The limit of participations per page"
      )

      resolve(&User.user_participations/3)
    end

    field(:memberships, :paginated_member_list,
      description: "The list of memberships for this user",
      meta: [private: true, rule: :"read:user:memberships"]
    ) do
      arg(:name, :string, description: "A name to filter members by")

      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated memberships list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of memberships per page")
      resolve(&User.user_memberships/3)
    end

    field(:drafts, :paginated_event_list,
      description: "The list of draft events this user has created",
      meta: [private: true, rule: :"read:user:draft_events"]
    ) do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated drafts events list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of drafts events per page")
      resolve(&User.user_drafted_events/3)
    end

    field(:followed_group_events, :paginated_followed_group_events,
      description: "The suggested events from the groups this user follows",
      meta: [private: true, rule: :"read:user:group_suggested_events"]
    ) do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the follow group events list"
      )

      arg(:limit, :integer,
        default_value: 10,
        description: "The limit of follow group events per page"
      )

      arg(:after_datetime, :datetime,
        description: "Filter follow group events by event start datetime"
      )

      resolve(&User.user_followed_group_events/3)
    end

    field(:settings, :user_settings,
      description: "The list of settings for this user",
      meta: [private: true, rule: :"read:user:settings"]
    ) do
      resolve(&User.user_settings/3)
    end

    field(:last_sign_in_at, :datetime, description: "When the user previously signed-in")

    field(:last_sign_in_ip, :string,
      description: "The IP adress the user previously sign-in with"
    )

    field(:current_sign_in_at, :datetime, description: "When the user currenlty signed-in")

    field(:current_sign_in_ip, :string,
      description: "The IP adress the user's currently signed-in with"
    )

    field(:media, :paginated_media_list,
      description: "The user's media objects",
      meta: [private: true, rule: :"read:user:media"]
    ) do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated user media list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of user media per page")
      resolve(&User.user_medias/3)
    end

    field(:media_size, :integer,
      resolve: &Media.user_size/3,
      description: "The total size of all the media from this user (from all their actors)"
    )

    field(:activity_settings, list_of(:activity_setting),
      description: "The user's activity settings",
      meta: [private: true, rule: :"read:user:activity_settings"]
    ) do
      resolve(&ActivitySettings.user_activity_settings/3)
    end

    field(:auth_authorized_applications, list_of(:auth_application_token),
      description: "The user's authorized authentication apps",
      meta: [private: true, rule: :forbid_app_access]
    ) do
      resolve(&ApplicationResolver.get_user_applications/3)
    end

    @desc "The list of conversations this person has"
    field(:conversations, :paginated_conversation_list,
      meta: [private: true, rule: :"read:profile:conversations"]
    ) do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the conversations list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of conversations per page")
      resolve(&Conversation.list_conversations/3)
    end
  end

  @desc "The list of roles an user can have"
  enum :user_role do
    value(:administrator, description: "Administrator role")
    value(:moderator, description: "Moderator role")
    value(:user, description: "User role")
  end

  @desc "Token"
  object :refreshed_token do
    meta(:authorize, :all)
    field(:access_token, non_null(:string), description: "Generated access token")
    field(:refresh_token, non_null(:string), description: "Generated refreshed token")
  end

  @desc "Users list"
  object :users do
    meta(:authorize, [:administrator, :moderator])
    field(:total, non_null(:integer), description: "Total elements")
    field(:elements, non_null(list_of(:user)), description: "User elements")
  end

  @desc "The list of sortable fields for an user list"
  enum :sortable_user_field do
    value(:id, description: "The user's ID")
  end

  @desc """
  A set of user settings
  """
  object :user_settings do
    meta(:authorize, :user)
    field(:timezone, :timezone, description: "The timezone for this user")

    field(:notification_on_day, :boolean,
      description: "Whether this user will receive an email at the start of the day of an event."
    )

    field(:notification_each_week, :boolean,
      description: "Whether this user will receive an weekly event recap"
    )

    field(:notification_before_event, :boolean,
      description: "Whether this user will receive a notification right before event"
    )

    field(:notification_pending_participation, :notification_pending_enum,
      description: "When does the user receives a notification about new pending participations"
    )

    field(:notification_pending_membership, :notification_pending_enum,
      description:
        "When does the user receives a notification about a new pending membership in one of the group they're admin for"
    )

    field(:group_notifications, :notification_pending_enum,
      description: "When does the user receives a notification about new activity"
    )

    field(:location, :location,
      description: "The user's preferred location, where they want to be suggested events"
    )
  end

  @desc "The list of values the for pending notification settings"
  enum :notification_pending_enum do
    value(:none, as: :none, description: "None. The notification won't be sent.")

    value(:direct,
      as: :direct,
      description: "Direct. The notification will be sent right away each time."
    )

    value(:one_hour,
      as: :one_hour,
      description: "One hour. Notifications will be sent at most each hour"
    )

    value(:one_day,
      as: :one_day,
      description: "One day. Notifications will be sent at most each day"
    )

    value(:one_week,
      as: :one_week,
      description: "One Week. Notifications will be sent at most each week"
    )
  end

  object :location do
    meta(:authorize, :user)
    field(:range, :integer, description: "The range in kilometers the user wants to see events")

    field(:geohash, :string, description: "A geohash representing the user's preferred location")

    field(:name, :string, description: "A string describing the user's preferred  location")
  end

  @desc """
  The set of parameters needed to input a location
  """
  input_object :location_input do
    field(:range, :integer, description: "The range in kilometers the user wants to see events")

    field(:geohash, :string, description: "A geohash representing the user's preferred location")

    field(:name, :string, description: "A string describing the user's preferred  location")
  end

  object :user_queries do
    @desc "Get an user"
    field :user, :user do
      arg(:id, non_null(:id))
      middleware(Rajska.QueryAuthorization, permit: [:administrator, :moderator], scope: false)
      resolve(&User.find_user/3)
    end

    @desc "Get the current user"
    field :logged_user, :user do
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&User.get_current_user/3)
    end

    @desc "List instance users"
    field :users, :users do
      arg(:email, :string, default_value: "", description: "Filter users by email")

      arg(:current_sign_in_ip, :string,
        description: "Filter users by current signed-in IP address"
      )

      arg(:page, :integer, default_value: 1, description: "The page in the paginated users list")
      arg(:limit, :integer, default_value: 10, description: "The limit of users per page")

      arg(:sort, :sortable_user_field, default_value: :id, description: "Sort column")
      arg(:direction, :sort_direction, default_value: :desc, description: "Sort direction")
      middleware(Rajska.QueryAuthorization, permit: [:administrator, :moderator], scope: false)
      resolve(&User.list_users/3)
    end
  end

  object :user_mutations do
    @desc "Create an user"
    field :create_user, type: :user do
      arg(:email, non_null(:string), description: "The new user's email")
      arg(:password, non_null(:string), description: "The new user's password")
      arg(:locale, :string, description: "The new user's locale")
      middleware(Rajska.QueryAuthorization, permit: :all)
      middleware(Rajska.RateLimiter, limit: user_ip_limiter(@env))
      middleware(Rajska.RateLimiter, keys: :email, limit: user_email_limiter(@env))
      resolve(&User.create_user/3)
    end

    @desc "Validate an user after registration"
    field :validate_user, type: :login do
      arg(:token, non_null(:string),
        description: "The token that will be used to validate the user"
      )

      middleware(Rajska.QueryAuthorization, permit: :all)
      resolve(&User.validate_user/3)
    end

    @desc "Resend registration confirmation token"
    field :resend_confirmation_email, type: :string do
      arg(:email, non_null(:string), description: "The email used to register")
      arg(:locale, :string, description: "The user's locale")
      middleware(Rajska.QueryAuthorization, permit: :all)
      middleware(Rajska.RateLimiter, limit: user_ip_limiter(@env))
      middleware(Rajska.RateLimiter, keys: :email, limit: user_email_limiter(@env))
      resolve(&User.resend_confirmation_email/3)
    end

    @desc "Send a link through email to reset user password"
    field :send_reset_password, type: :string do
      arg(:email, non_null(:string), description: "The user's email")
      arg(:locale, :string, description: "The user's locale")
      middleware(Rajska.QueryAuthorization, permit: :all)
      middleware(Rajska.RateLimiter, limit: user_ip_limiter(@env))
      middleware(Rajska.RateLimiter, keys: :email, limit: user_email_limiter(@env))
      resolve(&User.send_reset_password/3)
    end

    @desc "Reset user password"
    field :reset_password, type: :login do
      arg(:token, non_null(:string),
        description: "The user's token that will be used to reset the password"
      )

      arg(:password, non_null(:string), description: "The new password")
      arg(:locale, :string, default_value: "en", description: "The user's locale")
      middleware(Rajska.QueryAuthorization, permit: :all)
      resolve(&User.reset_password/3)
    end

    @desc "Login an user"
    field :login, type: :login do
      arg(:email, non_null(:string), description: "The user's email")
      arg(:password, non_null(:string), description: "The user's password")
      middleware(Rajska.QueryAuthorization, permit: :all)
      middleware(Rajska.RateLimiter, limit: user_ip_limiter(@env))
      middleware(Rajska.RateLimiter, keys: :email, limit: user_email_limiter(@env))
      resolve(&User.login_user/3)
    end

    @desc "Refresh a token"
    field :refresh_token, type: :refreshed_token do
      arg(:refresh_token, non_null(:string), description: "A refresh token")
      middleware(Rajska.QueryAuthorization, permit: :all)
      resolve(&User.refresh_token/3)
    end

    @desc "Logout an user, deleting a refresh token"
    field :logout, :string do
      arg(:refresh_token, non_null(:string))
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&User.logout/3)
    end

    @desc "Change default actor for user"
    field :change_default_actor, :user do
      arg(:preferred_username, non_null(:string), description: "The actor preferred_username")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&User.change_default_actor/3)
    end

    @desc "Change an user password"
    field :change_password, :user do
      arg(:old_password, non_null(:string), description: "The user's current password")
      arg(:new_password, non_null(:string), description: "The user's new password")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&User.change_password/3)
    end

    @desc "Change an user email"
    field :change_email, :user do
      arg(:email, non_null(:string), description: "The user's new email")
      arg(:password, non_null(:string), description: "The user's current password")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&User.change_email/3)
    end

    @desc "Validate an user email"
    field :validate_email, :user do
      arg(:token, non_null(:string),
        description: "The token that will be used to validate the email change"
      )

      middleware(Rajska.QueryAuthorization, permit: :all)
      resolve(&User.validate_email/3)
    end

    @desc "Delete an account"
    field :delete_account, :deleted_object do
      arg(:password, :string, description: "The user's password")
      arg(:user_id, :id, description: "The user's ID")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&User.delete_account/3)
    end

    @desc "Set user settings"
    field :set_user_settings, :user_settings do
      arg(:timezone, :timezone, description: "The timezone for this user")

      arg(:notification_on_day, :boolean,
        description:
          "Whether this user will receive an email at the start of the day of an event."
      )

      arg(:notification_each_week, :boolean,
        description: "Whether this user will receive an weekly event recap"
      )

      arg(:notification_before_event, :boolean,
        description: "Whether this user will receive a notification right before event"
      )

      arg(:notification_pending_participation, :notification_pending_enum,
        description: "When does the user receives a notification about new pending participations"
      )

      arg(:notification_pending_membership, :notification_pending_enum,
        description:
          "When does the user receives a notification about a new pending membership in one of the group they're admin for"
      )

      arg(:group_notifications, :notification_pending_enum,
        description: "When does the user receives a notification about new activity"
      )

      arg(:location, :location_input,
        description: "A geohash of the user's preferred location, where they want to see events"
      )

      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&User.set_user_setting/3)
    end

    @desc "Update the user's locale"
    field :update_locale, :user do
      arg(:locale, :string, description: "The user's new locale")
      middleware(Rajska.QueryAuthorization, permit: :user, scope: false)
      resolve(&User.update_locale/3)
    end
  end

  defp user_ip_limiter(:test), do: @user_ip_limit * 1000
  defp user_ip_limiter(_), do: @user_ip_limit

  defp user_email_limiter(:test), do: @user_email_limit * 1000
  defp user_email_limiter(_), do: @user_email_limit
end
