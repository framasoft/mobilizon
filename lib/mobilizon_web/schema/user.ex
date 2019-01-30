defmodule MobilizonWeb.Schema.UserType do
  @moduledoc """
  Schema representation for User
  """
  use Absinthe.Schema.Notation
  alias MobilizonWeb.Resolvers.User
  import MobilizonWeb.Schema.Utils

  @desc "A local user of Mobilizon"
  object :user do
    field(:id, non_null(:id), description: "The user's ID")
    field(:email, non_null(:string), description: "The user's email")

    field(:profiles, non_null(list_of(:person)),
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
  end

  object :user_mutations do
    @desc "Create an user"
    field :create_user, type: :user do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))

      resolve(handle_errors(&User.create_user/3))
    end

    @desc "Validate an user after registration"
    field :validate_user, type: :login do
      arg(:token, non_null(:string))
      resolve(&User.validate_user/3)
    end

    @desc "Resend registration confirmation token"
    field :resend_confirmation_email, type: :string do
      arg(:email, non_null(:string))
      arg(:locale, :string, default_value: "en")
      resolve(&User.resend_confirmation_email/3)
    end

    @desc "Send a link through email to reset user password"
    field :send_reset_password, type: :string do
      arg(:email, non_null(:string))
      arg(:locale, :string, default_value: "en")
      resolve(&User.send_reset_password/3)
    end

    @desc "Reset user password"
    field :reset_password, type: :login do
      arg(:token, non_null(:string))
      arg(:password, non_null(:string))
      arg(:locale, :string, default_value: "en")
      resolve(&User.reset_password/3)
    end

    @desc "Login an user"
    field :login, :login do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      resolve(&User.login_user/3)
    end

    @desc "Change default actor for user"
    field :change_default_actor, :user do
      arg(:preferred_username, non_null(:string))
      resolve(&User.change_default_actor/3)
    end
  end
end
