defmodule Mobilizon.GraphQL.Schema.Users.ActivitySetting do
  @moduledoc """
  Schema representation for PushSubscription
  """
  use Absinthe.Schema.Notation
  alias Mobilizon.GraphQL.Resolvers.Users.ActivitySettings
  alias Mobilizon.Users.ActivitySetting

  object :activity_setting do
    meta(:authorize, :user)
    field(:key, :string)
    field(:method, :string)
    field(:enabled, :boolean)
    field(:user, :user)
  end

  object :activity_setting_mutations do
    field :update_activity_setting, :activity_setting do
      arg(:key, non_null(:string))
      arg(:method, non_null(:string))
      arg(:enabled, non_null(:boolean))

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: ActivitySetting,
        rule: :"write:user:setting:activity",
        args: %{key: :key}
      )

      resolve(&ActivitySettings.upsert_user_activity_setting/3)
    end
  end
end
