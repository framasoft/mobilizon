defmodule Mobilizon.GraphQL.Schema.ConfigType do
  @moduledoc """
  Schema representation for User
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.Config

  @desc "A config object"
  object :config do
    # Instance name
    field(:name, :string)
    field(:description, :string)

    field(:registrations_open, :boolean)
    field(:registrations_whitelist, :boolean)
    field(:demo_mode, :boolean)
    field(:country_code, :string)
    field(:location, :lonlat)
    field(:geocoding, :geocoding)
    field(:maps, :maps)
    field(:anonymous, :anonymous)
    field(:resource_providers, list_of(:resource_provider))
    field(:timezones, list_of(:string))
    field(:features, :features)

    field(:terms, :terms, description: "The instance's terms") do
      arg(:locale, :string, default_value: "en")
      resolve(&Config.terms/3)
    end
  end

  object :terms do
    field(:url, :string)
    field(:type, :instance_terms_type)
    field(:body_html, :string)
  end

  object :lonlat do
    field(:longitude, :float)
    field(:latitude, :float)
    field(:accuracy_radius, :integer)
  end

  object :geocoding do
    field(:autocomplete, :boolean)
    field(:provider, :string)
  end

  object :maps do
    field(:tiles, :tiles)
  end

  object :tiles do
    field(:endpoint, :string)
    field(:attribution, :string)
  end

  object :anonymous do
    field(:participation, :anonymous_participation)
    field(:event_creation, :anonymous_event_creation)
    field(:actor_id, :id)
  end

  object :anonymous_participation do
    field(:allowed, :boolean)
    field(:validation, :anonymous_participation_validation)
  end

  object :anonymous_participation_validation do
    field(:email, :anonymous_participation_validation_email)
    field(:captcha, :anonymous_participation_validation_captcha)
  end

  object :anonymous_participation_validation_email do
    field(:enabled, :boolean)
    field(:confirmation_required, :boolean)
  end

  object :anonymous_participation_validation_captcha do
    field(:enabled, :boolean)
  end

  object :anonymous_event_creation do
    field(:allowed, :boolean)
    field(:validation, :anonymous_event_creation_validation)
  end

  object :anonymous_event_creation_validation do
    field(:email, :anonymous_event_creation_validation_email)
    field(:captcha, :anonymous_event_creation_validation_captcha)
  end

  object :anonymous_event_creation_validation_email do
    field(:enabled, :boolean)
    field(:confirmation_required, :boolean)
  end

  object :anonymous_event_creation_validation_captcha do
    field(:enabled, :boolean)
  end

  object :resource_provider do
    field(:type, :string)
    field(:endpoint, :string)
    field(:software, :string)
  end

  object :features do
    field(:groups, :boolean)
  end

  object :config_queries do
    @desc "Get the instance config"
    field :config, :config do
      resolve(&Config.get_config/3)
    end
  end
end
