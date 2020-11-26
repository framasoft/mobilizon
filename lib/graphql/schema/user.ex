defmodule Mobilizon.GraphQL.Schema.UserType do
  @moduledoc """
  Schema representation for User
  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Mobilizon.Events
  alias Mobilizon.GraphQL.Resolvers.{Media, User}
  alias Mobilizon.GraphQL.Schema

  import_types(Schema.SortType)

  @desc "A local user of Mobilizon"
  object :user do
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
      resolve: dataloader(Events),
      description: "A list of the feed tokens for this user"
    )

    field(:role, :user_role, description: "The role for the user")

    field(:locale, :string, description: "The user's locale")

    field(:provider, :string, description: "The user's login provider")

    field(:disabled, :boolean, description: "Whether the user is disabled")

    field(:participations, :paginated_participant_list,
      description: "The list of participations this user has"
    ) do
      arg(:after_datetime, :datetime, description: "Filter participations by event start datetime")

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
      description: "The list of memberships for this user"
    ) do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated memberships list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of memberships per page")
      resolve(&User.user_memberships/3)
    end

    field(:drafts, list_of(:event), description: "The list of draft events this user has created") do
      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated drafts events list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of drafts events per page")
      resolve(&User.user_drafted_events/3)
    end

    field(:settings, :user_settings, description: "The list of settings for this user") do
      resolve(&User.user_settings/3)
    end

    field(:last_sign_in_at, :datetime, description: "When the user previously signed-in")

    field(:last_sign_in_ip, :string, description: "The IP adress the user previously sign-in with")

    field(:current_sign_in_at, :datetime, description: "When the user currenlty signed-in")

    field(:current_sign_in_ip, :string,
      description: "The IP adress the user's currently signed-in with"
    )

    field(:media, :paginated_media_list, description: "The user's media objects") do
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
  end

  @desc "The list of roles an user can have"
  enum :user_role do
    value(:administrator, description: "Administrator role")
    value(:moderator, description: "Moderator role")
    value(:user, description: "User role")
  end

  @desc "Token"
  object :refreshed_token do
    field(:access_token, non_null(:string), description: "Generated access token")
    field(:refresh_token, non_null(:string), description: "Generated refreshed token")
  end

  @desc "Users list"
  object :users do
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
    field(:timezone, :string, description: "The timezone for this user")

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
  end

  object :user_queries do
    @desc "Get an user"
    field :user, :user do
      arg(:id, non_null(:id))
      resolve(&User.find_user/3)
    end

    @desc "Get the current user"
    field :logged_user, :user do
      resolve(&User.get_current_user/3)
    end

    @desc "List instance users"
    field :users, :users do
      arg(:email, :string, default_value: "", description: "Filter users by email")
      arg(:page, :integer, default_value: 1, description: "The page in the paginated users list")
      arg(:limit, :integer, default_value: 10, description: "The limit of users per page")

      arg(:sort, :sortable_user_field, default_value: :id, description: "Sort column")
      arg(:direction, :sort_direction, default_value: :desc, description: "Sort direction")

      resolve(&User.list_users/3)
    end
  end

  object :user_mutations do
    @desc "Create an user"
    field :create_user, type: :user do
      arg(:email, non_null(:string), description: "The new user's email")
      arg(:password, non_null(:string), description: "The new user's password")
      arg(:locale, :string, description: "The new user's locale")

      resolve(&User.create_user/3)
    end

    @desc "Validate an user after registration"
    field :validate_user, type: :login do
      arg(:token, non_null(:string),
        description: "The token that will be used to validate the user"
      )

      resolve(&User.validate_user/3)
    end

    @desc "Resend registration confirmation token"
    field :resend_confirmation_email, type: :string do
      arg(:email, non_null(:string), description: "The email used to register")
      arg(:locale, :string, description: "The user's locale")
      resolve(&User.resend_confirmation_email/3)
    end

    @desc "Send a link through email to reset user password"
    field :send_reset_password, type: :string do
      arg(:email, non_null(:string), description: "The user's email")
      arg(:locale, :string, description: "The user's locale")
      resolve(&User.send_reset_password/3)
    end

    @desc "Reset user password"
    field :reset_password, type: :login do
      arg(:token, non_null(:string),
        description: "The user's token that will be used to reset the password"
      )

      arg(:password, non_null(:string), description: "The new password")
      arg(:locale, :string, default_value: "en", description: "The user's locale")
      resolve(&User.reset_password/3)
    end

    @desc "Login an user"
    field :login, type: :login do
      arg(:email, non_null(:string), description: "The user's email")
      arg(:password, non_null(:string), description: "The user's password")
      resolve(&User.login_user/3)
    end

    @desc "Refresh a token"
    field :refresh_token, type: :refreshed_token do
      arg(:refresh_token, non_null(:string), description: "A refresh token")
      resolve(&User.refresh_token/3)
    end

    @desc "Change default actor for user"
    field :change_default_actor, :user do
      arg(:preferred_username, non_null(:string), description: "The actor preferred_username")
      resolve(&User.change_default_actor/3)
    end

    @desc "Change an user password"
    field :change_password, :user do
      arg(:old_password, non_null(:string), description: "The user's current password")
      arg(:new_password, non_null(:string), description: "The user's new password")
      resolve(&User.change_password/3)
    end

    @desc "Change an user email"
    field :change_email, :user do
      arg(:email, non_null(:string), description: "The user's new email")
      arg(:password, non_null(:string), description: "The user's current password")
      resolve(&User.change_email/3)
    end

    @desc "Validate an user email"
    field :validate_email, :user do
      arg(:token, non_null(:string),
        description: "The token that will be used to validate the email change"
      )

      resolve(&User.validate_email/3)
    end

    @desc "Delete an account"
    field :delete_account, :deleted_object do
      arg(:password, :string, description: "The user's password")
      arg(:user_id, :id, description: "The user's ID")
      resolve(&User.delete_account/3)
    end

    @desc "Set user settings"
    field :set_user_settings, :user_settings do
      arg(:timezone, :string, description: "The timezone for this user")

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

      resolve(&User.set_user_setting/3)
    end

    @desc "Update the user's locale"
    field :update_locale, :user do
      arg(:locale, :string, description: "The user's new locale")
      resolve(&User.update_locale/3)
    end
  end
end
