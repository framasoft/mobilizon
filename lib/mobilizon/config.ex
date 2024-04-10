defmodule Mobilizon.Config do
  @moduledoc """
  Configuration wrapper.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Admin
  alias Mobilizon.Medias.Media
  alias Mobilizon.Service.GitStatus
  require Logger
  import Mobilizon.Service.Export.Participants.Common, only: [enabled_formats: 0]

  @type mobilizon_config :: [
          name: String.t(),
          description: String.t(),
          hostname: String.t(),
          registrations_open: boolean(),
          languages: list(String.t()),
          default_language: String.t(),
          registration_email_allowlist: list(String.t()),
          registration_email_denylist: list(String.t()),
          demo: boolean(),
          repository: String.t(),
          email_from: String.t(),
          email_reply_to: String.t(),
          federating: boolean(),
          remove_orphan_uploads: boolean()
        ]

  @spec instance_config :: mobilizon_config
  def instance_config, do: Application.get_env(:mobilizon, :instance)

  @spec config_cache :: map()
  def config_cache do
    case Cachex.fetch(
           :config,
           :all_db_config,
           fn _key -> {:commit, Admin.get_all_admin_settings()} end
         ) do
      {status, value} when status in [:ok, :commit] -> value
      _err -> %{}
    end
  end

  @spec config_cached_value(String.t(), String.t(), String.t()) :: any()
  def config_cached_value(group, name, fallback \\ nil) do
    config_cache()
    |> Map.get(group, %{})
    |> Map.get(name, fallback)
  end

  @spec instance_name :: String.t()
  def instance_name,
    do:
      config_cached_value(
        "instance",
        "instance_name",
        instance_config()[:name]
      )

  @spec instance_description :: String.t()
  def instance_description,
    do:
      config_cached_value(
        "instance",
        "instance_description",
        instance_config()[:description]
      )

  @spec instance_long_description :: String.t()
  def instance_long_description,
    do:
      config_cached_value(
        "instance",
        "instance_long_description"
      )

  @spec instance_slogan :: String.t() | nil
  def instance_slogan, do: config_cached_value("instance", "instance_slogan")

  @spec instance_logo :: Media.t() | nil
  def instance_logo, do: config_cached_value("instance", "instance_logo")

  @spec instance_favicon :: Media.t() | nil
  def instance_favicon, do: config_cached_value("instance", "instance_favicon")

  @spec default_picture :: Media.t() | nil
  def default_picture, do: config_cached_value("instance", "default_picture")

  @spec primary_color :: Media.t() | nil
  def primary_color, do: config_cached_value("instance", "primary_color")

  @spec secondary_color :: Media.t() | nil
  def secondary_color, do: config_cached_value("instance", "secondary_color")

  @spec contact :: String.t() | nil
  def contact, do: config_cached_value("instance", "contact")

  @spec instance_terms(String.t()) :: String.t()
  def instance_terms(locale \\ "en") do
    config_cached_value("instance", "instance_terms", generate_terms(locale))
  end

  @spec instance_terms_type :: String.t()
  def instance_terms_type do
    config_cached_value("instance", "instance_terms_type", "DEFAULT")
  end

  @spec instance_terms_url :: String.t() | nil
  def instance_terms_url do
    config_cached_value("instance", "instance_terms_url")
  end

  @spec instance_privacy(String.t()) :: String.t()
  def instance_privacy(locale \\ "en") do
    config_cached_value(
      "instance",
      "instance_privacy_policy",
      generate_privacy(locale)
    )
  end

  @spec instance_privacy_type :: String.t()
  def instance_privacy_type do
    config_cached_value("instance", "instance_privacy_policy_type", "DEFAULT")
  end

  @spec instance_privacy_url :: String.t()
  def instance_privacy_url do
    config_cached_value("instance", "instance_privacy_policy_url")
  end

  @spec instance_rules :: String.t()
  def instance_rules do
    config_cached_value("instance", "instance_rules")
  end

  @spec instance_version :: String.t()
  def instance_version do
    GitStatus.commit()
  end

  @spec instance_hostname :: String.t()
  def instance_hostname, do: instance_config()[:hostname]

  @spec instance_registrations_open? :: boolean
  def instance_registrations_open?,
    do:
      to_boolean(
        config_cached_value(
          "instance",
          "registrations_open",
          instance_config()[:registrations_open]
        )
      )

  @spec instance_languages :: list(String.t())
  def instance_languages,
    do:
      config_cached_value(
        "instance",
        "instance_languages",
        instance_config()[:languages]
      )

  @spec default_language :: String.t()
  def default_language, do: instance_config()[:default_language]

  @spec instance_registrations_allowlist :: list(String.t())
  def instance_registrations_allowlist, do: instance_config()[:registration_email_allowlist]

  @spec instance_registrations_allowlist? :: boolean
  def instance_registrations_allowlist?, do: length(instance_registrations_allowlist()) > 0

  @spec instance_registrations_denylist :: list(String.t())
  def instance_registrations_denylist, do: instance_config()[:registration_email_denylist]

  @spec instance_demo_mode? :: boolean
  def instance_demo_mode?, do: to_boolean(instance_config()[:demo])

  @spec instance_long_events? :: boolean
  def instance_long_events?, do: instance_config()[:duration_of_long_event] > 0

  @spec instance_repository :: String.t()
  def instance_repository, do: instance_config()[:repository]

  @spec instance_email_from :: String.t()
  def instance_email_from, do: instance_config()[:email_from]

  @spec instance_email_reply_to :: String.t()
  def instance_email_reply_to, do: instance_config()[:email_reply_to]

  @spec instance_user_agent :: String.t()
  def instance_user_agent,
    do: "#{instance_hostname()} - Mobilizon #{instance_version()}"

  @spec instance_federating :: boolean()
  def instance_federating, do: instance_config()[:federating]

  @spec instance_geocoding_provider :: module()
  def instance_geocoding_provider,
    do: get_in(Application.get_env(:mobilizon, Mobilizon.Service.Geospatial), [:service])

  @spec instance_geocoding_autocomplete :: boolean
  def instance_geocoding_autocomplete,
    do: instance_geocoding_provider() !== Mobilizon.Service.Geospatial.Nominatim

  @spec maps_config :: [
          tiles: [endpoint: String.t(), attribution: String.t()],
          rounting: [type: atom]
        ]
  defp maps_config, do: Application.get_env(:mobilizon, :maps)

  @spec instance_maps_tiles_endpoint :: String.t()
  def instance_maps_tiles_endpoint, do: maps_config()[:tiles][:endpoint]

  @spec instance_maps_tiles_attribution :: String.t()
  def instance_maps_tiles_attribution,
    do: maps_config()[:tiles][:attribution]

  @spec instance_maps_routing_type :: atom()
  def instance_maps_routing_type,
    do: maps_config()[:routing][:type]

  @typep anonymous_config_type :: [
           participation: [
             allowed: boolean,
             validation: [
               email: [enabled: boolean(), confirmation_required: boolean()],
               captcha: [enabled: boolean()]
             ]
           ],
           event_creation: [
             allowed: boolean,
             validation: [
               email: [enabled: boolean(), confirmation_required: boolean()],
               captcha: [enabled: boolean()]
             ]
           ],
           reports: [
             allowed: boolean()
           ]
         ]

  @spec anonymous_config :: anonymous_config_type
  defp anonymous_config, do: Application.get_env(:mobilizon, :anonymous)

  @spec anonymous_participation? :: boolean
  def anonymous_participation?,
    do: anonymous_config()[:participation][:allowed]

  @spec anonymous_participation_email_required? :: boolean
  def anonymous_participation_email_required?,
    do: anonymous_config()[:participation][:validation][:email][:enabled]

  @spec anonymous_participation_email_confirmation_required? :: boolean
  def anonymous_participation_email_confirmation_required?,
    do:
      anonymous_config()[:participation][:validation][:email][
        :confirmation_required
      ]

  @spec anonymous_event_creation? :: boolean
  def anonymous_event_creation?,
    do: anonymous_config()[:event_creation][:allowed]

  @spec anonymous_event_creation_email_required? :: boolean
  def anonymous_event_creation_email_required?,
    do: anonymous_config()[:event_creation][:validation][:email][:enabled]

  @spec anonymous_event_creation_email_confirmation_required? :: boolean
  def anonymous_event_creation_email_confirmation_required?,
    do:
      anonymous_config()[:event_creation][:validation][:email][
        :confirmation_required
      ]

  @spec anonymous_event_creation_email_captcha_required? :: boolean
  def anonymous_event_creation_email_captcha_required?,
    do:
      anonymous_config()[:event_creation][:validation][:captcha][
        :enabled
      ]

  @spec anonymous_reporting? :: boolean
  def anonymous_reporting?,
    do: anonymous_config()[:reports][:allowed]

  @spec oauth_consumer_strategies() :: list({atom(), String.t()})
  def oauth_consumer_strategies do
    [:auth, :oauth_consumer_strategies]
    |> get([])
    |> Enum.map(fn strategy ->
      case strategy do
        {id, label} when is_atom(id) -> %{id: id, label: label}
        id when is_atom(id) -> %{id: id, label: nil}
      end
    end)
  end

  @spec ldap_enabled? :: boolean()
  def ldap_enabled?, do: get([:ldap, :enabled], false)

  @spec instance_resource_providers :: list(%{type: atom, software: atom, endpoint: String.t()})
  def instance_resource_providers do
    types = get_in(Application.get_env(:mobilizon, Mobilizon.Service.ResourceProviders), [:types])

    providers =
      get_in(Application.get_env(:mobilizon, Mobilizon.Service.ResourceProviders), [:providers])

    providers_map = :maps.filter(fn key, _value -> key in Keyword.values(types) end, providers)

    case Enum.count(providers_map) do
      0 ->
        []

      _ ->
        Enum.map(providers_map, fn {key, value} ->
          %{
            type: key,
            software: types |> Enum.find(fn {_key, val} -> val == key end) |> elem(0),
            endpoint: value
          }
        end)
    end
  end

  # config :mobilizon, :groups, enabled: true
  # config :mobilizon, :events, creation: true

  @spec instance_group_feature_enabled? :: boolean
  def instance_group_feature_enabled?,
    do: :mobilizon |> Application.get_env(:groups) |> Keyword.get(:enabled)

  @spec instance_event_creation_enabled? :: boolean
  def instance_event_creation_enabled?,
    do: :mobilizon |> Application.get_env(:events) |> Keyword.get(:creation)

  @spec instance_event_external_enabled? :: boolean
  def instance_event_external_enabled?,
    do: :mobilizon |> Application.get_env(:events) |> Keyword.get(:external)

  @spec instance_export_formats :: %{event_participants: list(String.t())}
  def instance_export_formats do
    %{
      event_participants: enabled_formats()
    }
  end

  @spec only_admin_can_create_groups? :: boolean
  def only_admin_can_create_groups?,
    do:
      :mobilizon
      |> Application.get_env(:restrictions)
      |> Keyword.get(:only_admin_can_create_groups)

  @spec only_groups_can_create_events? :: boolean
  def only_groups_can_create_events?,
    do:
      :mobilizon
      |> Application.get_env(:restrictions)
      |> Keyword.get(:only_groups_can_create_events)

  @spec anonymous_actor_id :: integer
  def anonymous_actor_id, do: get_cached_value(:anonymous_actor_id)

  @spec get(keys :: module | atom | [module | atom]) :: any
  def get(key), do: get(key, nil)

  @spec get(keys :: [module | atom], default :: any) :: any
  def get([key], default), do: get(key, default)

  def get([parent_key | keys], default) do
    case get_in(Application.get_env(:mobilizon, parent_key), keys) do
      nil -> default
      any -> any
    end
  end

  @spec get(key :: module | atom, default :: any) :: any
  def get(key, default), do: Application.get_env(:mobilizon, key, default)

  @spec get!(key :: module | atom) :: any | no_return
  def get!(key) do
    value = get(key, nil)

    if value == nil do
      raise("Missing configuration value: #{inspect(key)}")
    else
      value
    end
  end

  @spec put(keys :: [module | atom], value :: any) :: :ok
  def put([key], value), do: put(key, value)

  def put([parent_key | keys], value) do
    parent =
      Application.get_env(:mobilizon, parent_key, [])
      |> put_in(keys, value)

    Application.put_env(:mobilizon, parent_key, parent)
  end

  @spec put(keys :: module | atom, value :: any) :: :ok
  def put(key, value) do
    Application.put_env(:mobilizon, key, value)
  end

  @spec to_boolean(boolean | String.t()) :: boolean
  defp to_boolean(boolean), do: "true" == String.downcase("#{boolean}")

  @spec get_cached_value(atom) :: String.t() | integer | map
  defp get_cached_value(key) do
    case Cachex.fetch(:config, key, fn key ->
           case create_cache(key) do
             {:ok, value} when not is_nil(value) ->
               {:commit, value}

             {:error, err} ->
               Logger.debug("Failed to cache config value, returned: #{inspect(err)}")
               {:ignore, err}
           end
         end) do
      {status, value} when status in [:ok, :commit] -> value
      _err -> nil
    end
  end

  @spec create_cache(atom()) :: {:ok, integer() | map()} | {:error, Ecto.Changeset.t()}
  defp create_cache(:anonymous_actor_id) do
    case Actors.get_or_create_internal_actor("anonymous") do
      {:ok, %{id: actor_id}} ->
        {:ok, actor_id}

      {:error, err} ->
        {:error, err}
    end
  end

  defp create_cache(_), do: {:error, :cache_key_not_handled}

  @spec admin_settings :: map()
  def admin_settings do
    %{
      instance_description: instance_description(),
      instance_long_description: instance_long_description(),
      instance_name: instance_name(),
      instance_slogan: instance_slogan(),
      registrations_open: instance_registrations_open?(),
      contact: contact(),
      primary_color: primary_color(),
      secondary_color: secondary_color(),
      instance_logo: instance_logo(),
      instance_terms: instance_terms(),
      instance_terms_type: instance_terms_type(),
      instance_terms_url: instance_terms_url(),
      instance_privacy_policy: instance_privacy(),
      instance_privacy_policy_type: instance_privacy_type(),
      instance_privacy_policy_url: instance_privacy_url(),
      instance_rules: instance_rules(),
      instance_languages: instance_languages()
    }
  end

  @spec clear_config_cache :: {:ok | :error, integer}
  def clear_config_cache do
    Cachex.clear(:config)
  end

  @spec generate_terms(String.t()) :: String.t()
  def generate_terms(locale) do
    Gettext.put_locale(locale)

    Phoenix.View.render_to_string(
      Mobilizon.Web.APIView,
      "terms.html",
      %{
        instance_name: instance_name(),
        instance_url: instance_hostname(),
        instance_contact: instance_contact_html()
      }
    )
  end

  @spec generate_privacy(String.t()) :: String.t()
  def generate_privacy(locale) do
    Gettext.put_locale(locale)

    Phoenix.View.render_to_string(
      Mobilizon.Web.APIView,
      "privacy.html",
      %{instance_name: instance_name()}
    )
  end

  @spec instance_contact_html :: String.t()
  defp instance_contact_html do
    contact = contact()

    cond do
      is_nil(contact) ->
        "<b>Contact information not filled</b>"

      String.contains?(contact, "@") ->
        "<a href=\"mailto:#{contact}\">#{contact}</a>"

      String.match?(contact, ~r/^https?:\/\//) ->
        %URI{host: host} = URI.parse(contact)
        "<a href=\"#{contact}\">#{host}</a>"

      true ->
        contact
    end
  end
end
