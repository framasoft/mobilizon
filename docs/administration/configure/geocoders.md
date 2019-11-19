# Geocoders

Geocoding is the ability to match an input **string representing a location - such as an address - to geographical coordinates**.
Reverse geocoding is logically the opposite, matching **geographical coordinates to names of places**.

This is needed to set correct address for events, and more easily find events with geographical data, for instance if you want to discover events happening near your current position.

However, providing a geocoding service is quite expensive, especially if you want to cover the whole Earth.

!!!note
    To give an idea of what hardware is required to self-host a geocoding service, we successfully used Addok, Pelias and Mimirsbrunn on a 8 core/16GB RAM machine without any issues **on French data**.

## List of supported geocoders

This is the list of all geocoders supported by Mobilizon. The current default one is [Nominatim](#nominatim) and uses the official OpenStreetMap instance.

!!! bug
    Changing geocoder through `.env` configuration isn't currently supported by Mobilizon.
    Instead you need to edit the following line in `config.prod.exs`:
    ```elixir
    config :mobilizon, Mobilizon.Service.Geospatial, service: Mobilizon.Service.Geospatial.Nominatim
    ```
    And change `Nominatim` to one of the supported geocoders. This change might be overwritten when updating Mobilizon.

### Nominatim

[Nominatim](https://wiki.openstreetmap.org/wiki/Nominatim) is a GPL-2.0 licenced tool to search data by name and address. It's written in C and PHP and uses PostgreSQL.
It's the current default search tool on the [OpenStreetMap homepage](https://www.openstreetmap.org).

!!! warning
    When using the official Nominatim OpenStreetMap instance (default endpoint for this geocoder if not configured otherwise), you need to read and accept the [Usage Policy](https://operations.osmfoundation.org/policies/nominatim).

Several companies provide hosted instances of Nominatim that you can query via an API, for example see [MapQuest Open Initiative](https://developer.mapquest.com/documentation/open/nominatim-search).

### Addok

[Addok](https://github.com/addok/addok) is a WTFPL licenced search engine for address (and only address). It's written in Python and uses Redis. 
It's used by French government for [adresse.data.gouv.fr](https://adresse.data.gouv.fr).

!!! warning
    When using France's Addok instance at `api-adresse.data.gouv.fr` (default endpoint for this geocoder if not configured otherwise), you need to read and accept the [GCU](https://adresse.data.gouv.fr/cgu) (in French).

### Photon

[Photon](https://photon.komoot.de/) is an Apache 2.0 licenced search engine written in Java and powered by ElasticSearch.

!!! warning
    The terms of use for the official instance (default endpoint for this geocoder if not configured otherwise) are simply the following:
    > You can use the API for your project, but please be fair - extensive usage will be throttled. We do not guarantee for the availability and usage might be subject of change in the future.

### Pelias

[Pelias](https://github.com/pelias/pelias) is a MIT licensed geocoder composed of several services written in NodeJS. It's powered by ElasticSearch.

There's [Geocode Earth](https://geocode.earth/) SAAS that provides a Pelias API.
They offer discounts for Open-Source projects. [See the pricing](https://geocode.earth/).

### Mimirsbrunn

[Mimirsbrunn](https://github.com/CanalTP/mimirsbrunn) is an AGPL-3.0 licensed geocoding written in Rust and powered by ElasticSearch.

Mimirsbrunn is used by [Qwant Maps](https://www.qwant.com/maps) and [Navitia](https://www.navitia.io).

### Google Maps

[Google Maps](https://developers.google.com/maps/documentation/geocoding/intro) is a proprietary service that provides APIs for geocoding.

They don't have a free plan, but offer credit when creating a new account. [See the pricing](https://cloud.google.com/maps-platform/pricing/).

### MapQuest

[MapQuest](https://developer.mapquest.com/documentation/open/geocoding-api/) is a proprietary service that provides APIs for geocoding.

They offer a free plan. [See the pricing](https://developer.mapquest.com/plans).

### More geocoding services  

Geocoding implementations are simple modules that need to implement the [`Mobilizon.Service.Geospatial.Provider` behaviour](https://framasoft.frama.io/mobilizon/backend/Mobilizon.Service.Geospatial.Provider.html), so feel free to write your own!
