defmodule Mobilizon.GraphQL.Schema.AuthApplicationType do
  @moduledoc """
  Schema representation for an auth application
  """
  use Absinthe.Schema.Notation
  alias Mobilizon.GraphQL.Resolvers.Application

  @desc "An application"
  object :auth_application do
    field(:name, :string)
    field(:client_id, :string)
    field(:scopes, :string)
    field(:website, :string)
  end

  @desc "An application"
  object :auth_application_token do
    field(:id, :id)
    field(:inserted_at, :string)
    field(:last_used_at, :string)
    field(:application, :auth_application)
  end

  @desc "The informations returned after authorization"
  object :application_code_and_state do
    field(:code, :string)
    field(:state, :string)
  end

  object :auth_application_queries do
    @desc "Get an application"
    field :auth_application, :auth_application do
      arg(:client_id, non_null(:string), description: "The application's client_id")
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

      arg(:scope, :string, description: "The scope for the authorization")

      arg(:state, :string,
        description: "A state parameter to check that the request wasn't altered"
      )

      resolve(&Application.authorize/3)
    end

    field :revoke_application_token, :deleted_object do
      arg(:app_token_id, non_null(:string), description: "The application token's ID")
      resolve(&Application.revoke_application_token/3)
    end
  end
end
