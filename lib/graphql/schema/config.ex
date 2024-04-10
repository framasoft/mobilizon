defmodule Mobilizon.GraphQL.Schema.ConfigType do
  @moduledoc """
  Schema representation for User
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.Config

  @desc "A config object"
  object :config do
    meta(:authorize, :all)
    # Instance name
    field(:name, :string, description: "The instance's name")
    field(:description, :string, description: "The instance's short description")
    field(:long_description, :string, description: "The instance's long description")
    field(:slogan, :string, description: "The instance's slogan")
    field(:contact, :string, description: "The instance's contact details")

    field(:languages, list_of(:string), description: "The instance's admins languages")

    field(:event_categories, list_of(:event_category_option),
      description: "The instance list of event categories possibilities"
    ) do
      resolve(&Config.event_categories/3)
    end

    field(:registrations_open, :boolean, description: "Whether the registrations are opened")

    field(:registrations_allowlist, :boolean,
      description: "Whether the registration are on an allowlist"
    )

    field(:demo_mode, :boolean, description: "Whether the demo mode is enabled")
    field(:long_events, :boolean, description: "Whether the long events mode is enabled")
    field(:country_code, :string, description: "The country code from the IP")
    field(:location, :lonlat, description: "The IP's location")
    field(:geocoding, :geocoding, description: "The instance's geocoding settings")
    field(:maps, :maps, description: "The instance's maps settings")
    field(:anonymous, :anonymous, description: "The instance's anonymous action settings")

    field(:resource_providers, list_of(:resource_provider),
      description: "The instance's enabled resource providers"
    )

    field(:upload_limits, :upload_limits, description: "The configuration for upload limits")

    field(:timezones, list_of(:timezone), description: "The instance's available timezones")
    field(:features, :features, description: "The instance's features")
    field(:restrictions, :restrictions, description: "The instance's restrictions")
    field(:version, :string, description: "The instance's version")
    field(:federating, :boolean, description: "Whether this instance is federation")

    field(:terms, :terms, description: "The instance's terms") do
      arg(:locale, :string,
        default_value: "en",
        description:
          "The user's locale. The terms will be translated in their language, if available."
      )

      resolve(&Config.terms/3)
    end

    field(:instance_logo, :media, description: "The instance's logo") do
      resolve(&Config.instance_logo/3)
    end

    field(:default_picture, :media, description: "The default picture") do
      resolve(&Config.default_picture/3)
    end

    field(:primary_color, :string, description: "The instance's primary color")
    field(:secondary_color, :string, description: "The instance's secondary color")

    field(:privacy, :privacy, description: "The instance's privacy policy") do
      arg(:locale, :string,
        default_value: "en",
        description:
          "The user's locale. The privacy policy will be translated in their language, if available."
      )

      resolve(&Config.privacy/3)
    end

    field(:rules, :string, description: "The instance's rules")

    field(:auth, :auth, description: "The instance auth methods")
    field(:instance_feeds, :instance_feeds, description: "The instance's feed settings")
    field(:web_push, :web_push, description: "Web Push settings for the instance")

    field(:export_formats, :export_formats, description: "The instance list of export formats")

    field(:analytics, list_of(:analytics),
      description: "Configuration for diverse analytics services"
    )

    field(:search, :search_settings, description: "The instance's search settings")
  end

  @desc """
  The instance's terms configuration
  """
  object :terms do
    meta(:authorize, :all)
    field(:url, :string, description: "The instance's terms URL.")
    field(:type, :instance_terms_type, description: "The instance's terms type")
    field(:body_html, :string, description: "The instance's terms body text")
  end

  @desc """
  The instance's privacy policy configuration
  """
  object :privacy do
    meta(:authorize, :all)
    field(:url, :string, description: "The instance's privacy policy URL")
    field(:type, :instance_privacy_type, description: "The instance's privacy policy type")
    field(:body_html, :string, description: "The instance's privacy policy body text")
  end

  @desc """
  Geographic coordinates
  """
  object :lonlat do
    meta(:authorize, :all)
    field(:longitude, :float, description: "The coordinates longitude")
    field(:latitude, :float, description: "The coordinates latitude")
    # field(:accuracy_radius, :integer)
  end

  @desc """
  Instance geocoding configuration
  """
  object :geocoding do
    meta(:authorize, :all)

    field(:autocomplete, :boolean,
      description: "Whether autocomplete in address fields can be enabled"
    )

    field(:provider, :string, description: "The geocoding provider")
  end

  @desc """
  Instance maps configuration
  """
  object :maps do
    meta(:authorize, :all)
    field(:tiles, :tiles, description: "The instance's maps tiles configuration")
    field(:routing, :routing, description: "The instance's maps routing configuration")
  end

  @desc """
  Instance map tiles configuration
  """
  object :tiles do
    meta(:authorize, :all)
    field(:endpoint, :string, description: "The instance's tiles endpoint")
    field(:attribution, :string, description: "The instance's tiles attribution text")
  end

  @desc """
  Instance map routing configuration
  """
  object :routing do
    meta(:authorize, :all)
    field(:type, :routing_type, description: "The instance's routing type")
  end

  enum :routing_type do
    value(:openstreetmap, description: "Redirect to openstreetmap.org's direction endpoint")
    value(:google_maps, description: "Redirect to Google Maps's direction endpoint")
  end

  @desc """
  Instance anonymous configuration
  """
  object :anonymous do
    meta(:authorize, :all)

    field(:participation, :anonymous_participation,
      description: "The instance's anonymous participation settings"
    )

    field(:event_creation, :anonymous_event_creation,
      description: "The instance's anonymous event creation settings"
    )

    field(:reports, :anonymous_reports, description: "The instance's anonymous reports setting")

    field(:actor_id, :id,
      description: "The actor ID that should be used to perform anonymous actions"
    )
  end

  @desc """
  Instance anonymous participation configuration
  """
  object :anonymous_participation do
    meta(:authorize, :all)
    field(:allowed, :boolean, description: "Whether anonymous participations are allowed")

    field(:validation, :anonymous_participation_validation,
      description: "The ways to validate anonymous participations"
    )
  end

  @desc """
  Instance anonymous participation validation configuration
  """
  object :anonymous_participation_validation do
    meta(:authorize, :all)

    field(:email, :anonymous_participation_validation_email,
      description: "The policy to validate anonymous participations by email"
    )

    field(:captcha, :anonymous_participation_validation_captcha,
      description: "The policy to validate anonymous participations by captcha"
    )
  end

  @desc """
  Instance anonymous participation with validation by email configuration
  """
  object :anonymous_participation_validation_email do
    meta(:authorize, :all)

    field(:enabled, :boolean,
      description: "Whether anonymous participation validation by email is enabled"
    )

    field(:confirmation_required, :boolean,
      description: "Whether anonymous participation validation by email is required"
    )
  end

  @desc """
  Instance anonymous participation with validation by captcha configuration
  """
  object :anonymous_participation_validation_captcha do
    meta(:authorize, :all)

    field(:enabled, :boolean,
      description: "Whether anonymous participation validation by captcha is enabled"
    )
  end

  @desc """
  Instance anonymous event creation configuration
  """
  object :anonymous_event_creation do
    meta(:authorize, :all)
    field(:allowed, :boolean, description: "Whether anonymous event creation is enabled")

    field(:validation, :anonymous_event_creation_validation,
      description: "The methods to validate events created anonymously"
    )
  end

  @desc """
  Instance anonymous event creation validation configuration
  """
  object :anonymous_event_creation_validation do
    meta(:authorize, :all)

    field(:email, :anonymous_event_creation_validation_email,
      description: "The policy to validate anonymous event creations by email"
    )

    field(:captcha, :anonymous_event_creation_validation_captcha,
      description: "The policy to validate anonymous event creations by captcha"
    )
  end

  @desc """
  Instance anonymous event creation email validation configuration
  """
  object :anonymous_event_creation_validation_email do
    meta(:authorize, :all)

    field(:enabled, :boolean,
      description: "Whether anonymous event creation with email validation is enabled"
    )

    field(:confirmation_required, :boolean,
      description: "Whether anonymous event creation with email validation is required"
    )
  end

  @desc """
  Instance anonymous event creation captcha validation configuration
  """
  object :anonymous_event_creation_validation_captcha do
    meta(:authorize, :all)

    field(:enabled, :boolean,
      description: "Whether anonymous event creation with validation by captcha is enabled"
    )
  end

  @desc """
  Instance anonymous reports
  """
  object :anonymous_reports do
    meta(:authorize, :all)
    field(:allowed, :boolean, description: "Whether anonymous reports are allowed")
  end

  @desc """
  A resource provider details
  """
  object :resource_provider do
    meta(:authorize, :all)
    field(:type, :string, description: "The resource provider's type")
    field(:endpoint, :string, description: "The resource provider's endpoint")
    field(:software, :string, description: "The resource provider's software")
  end

  @desc """
  The instance's features
  """
  object :features do
    meta(:authorize, :all)
    field(:groups, :boolean, description: "Whether groups are activated on this instance")

    field(:event_creation, :boolean,
      description: "Whether event creation is allowed on this instance"
    )

    field(:event_external, :boolean,
      description: "Whether redirecting to external providers is authorized in event edition"
    )

    field(:antispam, :boolean, description: "Whether anti-spam is activated on this instance")
  end

  @desc """
  The instance's restrictions
  """
  object :restrictions do
    meta(:authorize, :all)

    field(:only_admin_can_create_groups, :boolean,
      description: "Whether groups creation is allowed only for admin, not for all users"
    )

    field(:only_groups_can_create_events, :boolean,
      description: "Whether events creation is allowed only for groups, not for persons"
    )
  end

  @desc """
  The instance's auth configuration
  """
  object :auth do
    meta(:authorize, :all)
    field(:ldap, :boolean, description: "Whether or not LDAP auth is enabled")
    field(:database_login, :boolean, description: "Whether or not database login is enabled")
    field(:oauth_providers, list_of(:oauth_provider), description: "List of oauth providers")
  end

  @desc """
  An oAuth Provider
  """
  object :oauth_provider do
    meta(:authorize, :all)
    field(:id, :string, description: "The provider ID")
    field(:label, :string, description: "The label for the auth provider")
  end

  @desc """
  An upload limits configuration
  """
  object :upload_limits do
    meta(:authorize, :all)
    field(:default, :integer, description: "The default limitation, in bytes")
    field(:avatar, :integer, description: "The avatar limitation, in bytes")
    field(:banner, :integer, description: "The banner limitation, in bytes")
  end

  object :instance_feeds do
    meta(:authorize, :all)
    field(:enabled, :boolean, description: "Whether the instance-wide feeds are enabled")
  end

  object :web_push do
    meta(:authorize, :all)
    field(:enabled, :boolean, description: "Whether the WebPush feature is enabled")
    field(:public_key, :string, description: "The server's public WebPush VAPID key")
  end

  object :analytics do
    meta(:authorize, :all)
    field(:id, :string, description: "ID of the analytics service")
    field(:enabled, :boolean, description: "Whether the service is activated or not")

    field(:configuration, list_of(:analytics_configuration),
      description: "A list of key-values configuration"
    )
  end

  enum :analytics_configuration_type do
    value(:string, description: "A string")
    value(:integer, description: "An integer")
    value(:boolean, description: "A boolean")
    value(:float, description: "A float")
  end

  object :analytics_configuration do
    meta(:authorize, :all)
    field(:key, :string, description: "The key for the analytics configuration element")
    field(:value, :string, description: "The value for the analytics configuration element")
    field(:type, :analytics_configuration_type, description: "The analytics configuration type")
  end

  object :search_settings do
    meta(:authorize, :all)
    field(:global, :global_search_settings, description: "The instance's global search settings")
  end

  object :global_search_settings do
    meta(:authorize, :all)
    field(:is_enabled, :boolean, description: "Whether global search is enabled")
    field(:is_default, :boolean, description: "Whether global search is the default")
  end

  @desc """
  Export formats configuration
  """
  object :export_formats do
    meta(:authorize, :all)

    field(:event_participants, list_of(:string),
      description: "The list of formats the event participants can be exported to"
    )
  end

  @desc """
  Event categories list configuration
  """
  object :event_category_option do
    meta(:authorize, :all)
    field(:id, :string, description: "The ID of the event category")
    field(:label, :string, description: "The translated name of the event category")
  end

  object :config_queries do
    @desc "Get the instance config"
    field :config, :config do
      middleware(Rajska.QueryAuthorization, permit: :all)
      resolve(&Config.get_config/3)
    end
  end
end
