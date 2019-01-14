defmodule MobilizonWeb.Schema.UserType do
  @moduledoc """
  Schema representation for User
  """
  use Absinthe.Schema.Notation

  @desc "A local user of Mobilizon"
  object :user do
    field(:id, non_null(:id), description: "The user's ID")
    field(:email, non_null(:string), description: "The user's email")

    field(:profiles, non_null(list_of(:person)),
      description: "The user's list of profiles (identities)"
    )

    field(:default_actor, non_null(:person), description: "The user's default actor")

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
end
