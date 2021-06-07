defmodule Mobilizon.GraphQL.Schema.Users.ActivitySetting do
  @moduledoc """
  Schema representation for PushSubscription
  """
  use Absinthe.Schema.Notation
  alias Mobilizon.GraphQL.Resolvers.Users.ActivitySettings

  object :activity_setting do
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
      resolve(&ActivitySettings.upsert_user_activity_setting/3)
    end
  end
end
