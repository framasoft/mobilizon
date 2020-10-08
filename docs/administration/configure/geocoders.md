# Geocoders

Geocoding is the ability to match an input **string representing a location - such as an address - to geographical coordinates**.
Reverse geocoding is logically the opposite, matching **geographical coordinates to names of places**.

This is needed to set correct address for events, and more easily find events with geographical data, for instance if you want to discover events happening near your current position.

However, providing a geocoding service is quite expensive, especially if you want to cover the whole Earth.

!!! note "Hardware setup"
    To give an idea of what hardware is required to self-host a geocoding service, we successfully installed and used [Addok](#addok), [Pelias](#pelias) and [Mimirsbrunn](#mimirsbrunn) on a 8 cores/16GB RAM machine without any issues **importing only European addresses and data**.

!!! tip "Advised provider"
    We had best results using the [Pelias](#pelias) geocoding provider.

## Change geocoder

To change geocoder backend, you need to add the following line in `prod.secret.exs`:
```elixir
config :mobilizon, Mobilizon.Service.Geospatial,
  service: Mobilizon.Service.Geospatial.Nominatim
```
And change `Nominatim` to one of the supported geocoders. Depending on the provider, you'll also need to add some special config to specify eventual endpoints or API keys.

For instance, when using `Mimirsbrunn`, you'll need the following configuration:
```elixir
config :mobilizon, Mobilizon.Service.Geospatial,
  service: Mobilizon.Service.Geospatial.Mimirsbrunn

config :mobilizon, Mobilizon.Service.Geospatial.Mimirsbrunn,
  endpoint: "https://my-mimir-instance.tld"
```

## List of supported geocoders

This is the list of all geocoders supported by Mobilizon. The current default one is [Nominatim](#nominatim) and uses the official OpenStreetMap instance.

### Nominatim

[Nominatim](https://wiki.openstreetmap.org/wiki/Nominatim) is a GPL-2.0 licenced tool to search data by name and address. It's written in C and PHP and uses PostgreSQL.
It's the current default search tool on the [OpenStreetMap homepage](https://www.openstreetmap.org).

!!! warning "Terms"
    When using the official Nominatim OpenStreetMap instance (default endpoint for this geocoder if not configured otherwise), you need to read and accept the [Usage Policy](https://operations.osmfoundation.org/policies/nominatim).

!!! danger "Limitations"
    Autocomplete is not possible using Nominatim, you'll obtain no suggestions while typing.

Several companies provide hosted instances of Nominatim that you can query via an API, for example see [MapQuest Open Initiative](https://developer.mapquest.com/documentation/open/nominatim-search).

** Default configuration **
```elixir
config :mobilizon, Mobilizon.Service.Geospatial.Nominatim,
  endpoint: "https://nominatim.openstreetmap.org",
  api_key: nil
```

### Addok

[Addok](https://github.com/addok/addok) is a MIT licenced search engine for address (and only address). It's written in Python and uses Redis. 
It's used by French government for [adresse.data.gouv.fr](https://adresse.data.gouv.fr).

!!! warning "Terms"
    When using France's Addok instance at `api-adresse.data.gouv.fr` (default endpoint for this geocoder if not configured otherwise), you need to read and accept the [GCU](https://adresse.data.gouv.fr/cgu) (in French).
    
** Default configuration **
```elixir
config :mobilizon, Mobilizon.Service.Geospatial.Addok,
  endpoint: "https://api-adresse.data.gouv.fr"
```

The default endpoint is limited to France. Geo coding outside of France will return an empty result. Moreover, as France is implicit for this endpoint, country is not part of the result.
To conform to `Provider` interface, this provider return "France" as the country.

If plugged to another endpoint, in another country, it could be useful to change the default country. This can be done in `prod.secret.exs`:

** change endpoint default country **
```elixir
config :mobilizon, Mobilizon.Service.Geospatial.Addok,
  endpoint: "https://another-endpoint.tld"
  default_country: "Country"
```

### Photon

[Photon](https://photon.komoot.de/) is an Apache 2.0 licenced search engine written in Java and powered by ElasticSearch.

!!! warning "Terms"
    The terms of use for the official instance (default endpoint for this geocoder if not configured otherwise) are simply the following:
    > You can use the API for your project, but please be fair - extensive usage will be throttled. We do not guarantee for the availability and usage might be subject of change in the future.
    
** Default configuration **
```elixir
config :mobilizon, Mobilizon.Service.Geospatial.Photon,
  endpoint: "https://photon.komoot.de"
```

### Pelias

[Pelias](https://github.com/pelias/pelias) is a MIT licensed geocoder composed of several services written in NodeJS. It's powered by ElasticSearch.

There's [Geocode Earth](https://geocode.earth/) SAAS that provides a Pelias API.
They offer discounts for Open-Source projects. [See the pricing](https://geocode.earth/).

**Configuration example**
```elixir
config :mobilizon, Mobilizon.Service.Geospatial.Pelias,
  endpoint: nil
```

### Mimirsbrunn

[Mimirsbrunn](https://github.com/CanalTP/mimirsbrunn) is an AGPL-3.0 licensed geocoding written in Rust and powered by ElasticSearch.

Mimirsbrunn is used by [Qwant Maps](https://www.qwant.com/maps) and [Navitia](https://www.navitia.io).

** Default configuration **
```elixir
config :mobilizon, Mobilizon.Service.Geospatial.Mimirsbrunn,
  endpoint: nil
```

### Google Maps

[Google Maps](https://developers.google.com/maps/documentation/geocoding/intro) is a proprietary service that provides APIs for geocoding.

They don't have a free plan, but offer credit when creating a new account. [See the pricing](https://cloud.google.com/maps-platform/pricing/).

** Default configuration **

!!! note
    `fetch_place_details` tells GoogleMaps to also fetch some details on a place when geocoding. It can be more expensive, since you're doing two requests to Google instead of one.

```elixir
config :mobilizon, Mobilizon.Service.Geospatial.GoogleMaps,
  api_key: nil,
  fetch_place_details: true
```

### MapQuest

[MapQuest](https://developer.mapquest.com/documentation/open/geocoding-api/) is a proprietary service that provides APIs for geocoding.

They offer a free plan. [See the pricing](https://developer.mapquest.com/plans).

** Default configuration **
```elixir
config :mobilizon, Mobilizon.Service.Geospatial.MapQuest,
  api_key: nil
```

### More geocoding services  

Geocoding implementations are simple modules that need to implement the [`Mobilizon.Service.Geospatial.Provider` behaviour](https://framasoft.frama.io/mobilizon/backend/Mobilizon.Service.Geospatial.Provider.html), so feel free to write your own!
