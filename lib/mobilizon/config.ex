defmodule Mobilizon.Config do
  @moduledoc """
  Configuration wrapper.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.GitStatus

  @spec instance_config :: keyword
  def instance_config, do: Application.get_env(:mobilizon, :instance)

  @spec instance_name :: String.t()
  def instance_name,
    do:
      Mobilizon.Admin.get_admin_setting_value(
        "instance",
        "instance_name",
        instance_config()[:name]
      )

  @spec instance_description :: String.t()
  def instance_description,
    do:
      Mobilizon.Admin.get_admin_setting_value(
        "instance",
        "instance_description",
        instance_config()[:description]
      )

  @spec instance_long_description :: String.t()
  def instance_long_description,
    do:
      Mobilizon.Admin.get_admin_setting_value(
        "instance",
        "instance_long_description"
      )

  @spec contact :: String.t()
  def contact do
    Mobilizon.Admin.get_admin_setting_value("instance", "contact")
  end

  @spec instance_terms(String.t()) :: String.t()
  def instance_terms(locale \\ "en") do
    Mobilizon.Admin.get_admin_setting_value("instance", "instance_terms", generate_terms(locale))
  end

  @spec instance_terms_type :: String.t()
  def instance_terms_type do
    Mobilizon.Admin.get_admin_setting_value("instance", "instance_terms_type", "DEFAULT")
  end

  @spec instance_terms_url :: String.t()
  def instance_terms_url do
    Mobilizon.Admin.get_admin_setting_value("instance", "instance_terms_url")
  end

  @spec instance_privacy(String.t()) :: String.t()
  def instance_privacy(locale \\ "en") do
    Mobilizon.Admin.get_admin_setting_value(
      "instance",
      "instance_privacy_policy",
      generate_privacy(locale)
    )
  end

  @spec instance_privacy_type :: String.t()
  def instance_privacy_type do
    Mobilizon.Admin.get_admin_setting_value("instance", "instance_privacy_policy_type", "DEFAULT")
  end

  @spec instance_privacy_url :: String.t()
  def instance_privacy_url do
    Mobilizon.Admin.get_admin_setting_value("instance", "instance_privacy_policy_url")
  end

  @spec instance_rules :: String.t()
  def instance_rules do
    Mobilizon.Admin.get_admin_setting_value("instance", "instance_rules")
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
        Mobilizon.Admin.get_admin_setting_value(
          "instance",
          "registrations_open",
          instance_config()[:registrations_open]
        )
      )

  @spec instance_registrations_whitelist :: list(String.t())
  def instance_registrations_whitelist, do: instance_config()[:registration_email_whitelist]

  @spec instance_registrations_whitelist? :: boolean
  def instance_registrations_whitelist?, do: length(instance_registrations_whitelist()) > 0

  @spec instance_demo_mode? :: boolean
  def instance_demo_mode?, do: to_boolean(instance_config()[:demo])

  @spec instance_repository :: String.t()
  def instance_repository, do: instance_config()[:repository]

  @spec instance_email_from :: String.t()
  def instance_email_from, do: instance_config()[:email_from]

  @spec instance_email_reply_to :: String.t()
  def instance_email_reply_to, do: instance_config()[:email_reply_to]

  @spec instance_user_agent :: String.t()
  def instance_user_agent,
    do: "#{instance_name()} #{instance_hostname()} - Mobilizon #{instance_version()}"

  @spec instance_federating :: String.t()
  def instance_federating, do: instance_config()[:federating]

  @spec instance_geocoding_provider :: atom()
  def instance_geocoding_provider,
    do: get_in(Application.get_env(:mobilizon, Mobilizon.Service.Geospatial), [:service])

  @spec instance_geocoding_autocomplete :: boolean
  def instance_geocoding_autocomplete,
    do: instance_geocoding_provider() !== Mobilizon.Service.Geospatial.Nominatim

  @spec instance_maps_tiles_endpoint :: String.t()
  def instance_maps_tiles_endpoint, do: Application.get_env(:mobilizon, :maps)[:tiles][:endpoint]

  @spec instance_maps_tiles_attribution :: String.t()
  def instance_maps_tiles_attribution,
    do: Application.get_env(:mobilizon, :maps)[:tiles][:attribution]

  @spec anonymous_participation? :: boolean
  def anonymous_participation?,
    do: Application.get_env(:mobilizon, :anonymous)[:participation][:allowed]

  @spec anonymous_participation_email_required? :: boolean
  def anonymous_participation_email_required?,
    do: Application.get_env(:mobilizon, :anonymous)[:participation][:validation][:email][:enabled]

  @spec anonymous_participation_email_confirmation_required? :: boolean
  def anonymous_participation_email_confirmation_required?,
    do:
      Application.get_env(:mobilizon, :anonymous)[:participation][:validation][:email][
        :confirmation_required
      ]

  @spec anonymous_participation_email_captcha_required? :: boolean
  def anonymous_participation_email_captcha_required?,
    do:
      Application.get_env(:mobilizon, :anonymous)[:participation][:validation][:captcha][:enabled]

  @spec anonymous_event_creation? :: boolean
  def anonymous_event_creation?,
    do: Application.get_env(:mobilizon, :anonymous)[:event_creation][:allowed]

  @spec anonymous_event_creation_email_required? :: boolean
  def anonymous_event_creation_email_required?,
    do:
      Application.get_env(:mobilizon, :anonymous)[:event_creation][:validation][:email][:enabled]

  @spec anonymous_event_creation_email_confirmation_required? :: boolean
  def anonymous_event_creation_email_confirmation_required?,
    do:
      Application.get_env(:mobilizon, :anonymous)[:event_creation][:validation][:email][
        :confirmation_required
      ]

  @spec anonymous_event_creation_email_captcha_required? :: boolean
  def anonymous_event_creation_email_captcha_required?,
    do:
      Application.get_env(:mobilizon, :anonymous)[:event_creation][:validation][:captcha][
        :enabled
      ]

  @spec anonymous_reporting? :: boolean
  def anonymous_reporting?,
    do: Application.get_env(:mobilizon, :anonymous)[:reports][:allowed]

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

  def instance_group_feature_enabled?, do: Application.get_env(:mobilizon, :instance)[:groups]

  def anonymous_actor_id, do: get_cached_value(:anonymous_actor_id)
  def relay_actor_id, do: get_cached_value(:relay_actor_id)

  @spec get(module | atom) :: any
  def get(key), do: get(key, nil)

  @spec get([module | atom]) :: any
  def get([key], default), do: get(key, default)

  def get([parent_key | keys], default) do
    case get_in(Application.get_env(:mobilizon, parent_key), keys) do
      nil -> default
      any -> any
    end
  end

  @spec get(module | atom, any) :: any
  def get(key, default), do: Application.get_env(:mobilizon, key, default)

  @spec get!(module | atom) :: any
  def get!(key) do
    value = get(key, nil)

    if value == nil do
      raise("Missing configuration value: #{inspect(key)}")
    else
      value
    end
  end

  @spec put([module | atom], any) :: any
  def put([key], value), do: put(key, value)

  def put([parent_key | keys], value) do
    parent = put_in(Application.get_env(:mobilizon, parent_key), keys, value)

    Application.put_env(:mobilizon, parent_key, parent)
  end

  @spec put(module | atom, any) :: any
  def put(key, value), do: Application.put_env(:mobilizon, key, value)

  @spec to_boolean(boolean | String.t()) :: boolean
  defp to_boolean(boolean), do: "true" == String.downcase("#{boolean}")

  defp get_cached_value(key) do
    case Cachex.fetch(:config, key, fn key ->
           case create_cache(key) do
             value when not is_nil(value) -> {:commit, value}
             err -> {:ignore, err}
           end
         end) do
      {status, value} when status in [:ok, :commit] -> value
      _err -> nil
    end
  end

  @spec create_cache(atom()) :: integer()
  defp create_cache(:anonymous_actor_id) do
    with {:ok, %Actor{id: actor_id}} <- Actors.get_or_create_internal_actor("anonymous") do
      actor_id
    end
  end

  @spec create_cache(atom()) :: integer()
  defp create_cache(:relay_actor_id) do
    with {:ok, %Actor{id: actor_id}} <- Actors.get_or_create_internal_actor("relay") do
      actor_id
    end
  end

  def clear_config_cache do
    Cachex.clear(:config)
  end

  def generate_terms(locale) do
    import Mobilizon.Web.Gettext
    put_locale(locale)

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

  def generate_privacy(locale) do
    import Mobilizon.Web.Gettext
    put_locale(locale)

    Phoenix.View.render_to_string(
      Mobilizon.Web.APIView,
      "privacy.html",
      %{instance_name: instance_name()}
    )
  end

  defp instance_contact_html do
    contact = contact()

    cond do
      is_nil(contact) ->
        nil

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
