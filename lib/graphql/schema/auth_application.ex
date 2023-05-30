defmodule Mobilizon.GraphQL.Schema.AuthApplicationType do
  @moduledoc """
  Schema representation for an auth application
  """
  use Absinthe.Schema.Notation
  alias Mobilizon.GraphQL.Resolvers.Application

  @desc "An application"
  object :auth_application do
    meta(:authorize, :user)
    field(:id, :id)
    field(:name, :string)
    field(:client_id, :string)
    field(:scope, :string)
    field(:website, :string)
  end

  @desc "An application"
  object :auth_application_token do
    meta(:authorize, :user)
    field(:id, :id)
    field(:inserted_at, :string)
    field(:last_used_at, :string)
    field(:application, :auth_application)
  end

  @desc "The informations returned after authorization"
  object :application_code_and_state do
    meta(:authorize, :user)
    field(:code, :string)
    field(:state, :string)
    field(:client_id, :string)
    field(:scope, :string)
  end

  object :application_device_activation do
    meta(:authorize, :user)
    field(:id, :id)
    field(:application, :auth_application)
    field(:scope, :string)
  end

  object :auth_application_queries do
    @desc "Get an application"
    field :auth_application, :auth_application do
      arg(:client_id, non_null(:string), description: "The application's client_id")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Applications.Application,
        rule: :forbid_app_access,
        args: %{client_id: :client_id}
      )

      resolve(&Application.get_application/3)
    end
  end

  object :auth_application_mutations do
    @desc "Authorize an application"
    field :authorize_application, :application_code_and_state do
      arg(:client_id, non_null(:string), description: "The application's client_id")

      arg(:redirect_uri, non_null(:string),
        description: "The URI to redirect to with the code and state"
      )

      arg(:scope, non_null(:string), description: "The scope for the authorization")

      arg(:state, :string,
        description: "A state parameter to check that the request wasn't altered"
      )

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Applications.Application,
        rule: :forbid_app_access,
        args: %{client_id: :client_id}
      )

      resolve(&Application.authorize/3)
    end

    @desc "Revoke an authorized application"
    field :revoke_application_token, :deleted_object do
      arg(:app_token_id, non_null(:string), description: "The application token's ID")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Applications.ApplicationToken,
        rule: :forbid_app_access,
        args: %{id: :app_token_id}
      )

      resolve(&Application.revoke_application_token/3)
    end

    @desc "Activate an user device"
    field :device_activation, :application_device_activation do
      arg(:user_code, non_null(:string),
        description: "The code provided by the application entered by the user"
      )

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Applications.ApplicationDeviceActivation,
        rule: :forbid_app_access,
        args: %{id: :user_code}
      )

      resolve(&Application.activate_device/3)
    end

    @desc "Authorize an user device"
    field :authorize_device_application, :auth_application do
      arg(:client_id, non_null(:string), description: "The application's client_id")

      arg(:user_code, non_null(:string),
        description: "The code provided by the application entered by the user"
      )

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Applications.ApplicationDeviceActivation,
        rule: :forbid_app_access,
        args: %{id: :client_id}
      )

      resolve(&Application.authorize_device_application/3)
    end
  end
end
