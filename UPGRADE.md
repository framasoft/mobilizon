# Upgrading from 1.3 to 2.0

Requirements dependencies depend on the way Mobilizon is installed.
## New Elixir version requirement
### Docker and Release install

You are already using latest Elixir version in the release tarball and Docker images.

### Source install

**Elixir 1.12 and Erlang OTP 22 are now required**. If your distribution or the repositories from Erlang Solutions don't provide these versions, you need to uninstall the current versions and install [Elixir](https://github.com/asdf-vm/asdf-elixir) through the [ASDF tool](https://asdf-vm.com/).

## Geographic timezone data

Mobilizon 2.0 uses data based on [timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder) (which is based itself on OpenStreetMap data) to determine the timezone of an event automatically, based on it's geocoordinates. However, this needs ~700Mio of disk, so we don't redistribute data directly, depending on the case. It's possible to skip this part, but users will need to manually pick the timezone for every event they created when it has a different timezone from their own.

### Docker install

The geographic timezone data is already bundled into the image, you have nothing to do.
### Release install

In order to keep the release tarballs light, the geographic timezone data is not bundled directly. You need to download the data :
* either raw from Github, but **requires an extra ~1Gio of memory** to process the data

  ```sh
  sudo -u mobilizon mkdir /var/lib/mobilizon/timezones
  sudo -u mobilizon ./bin/mobilizon_ctl tz_world.update
  ```

* either already processed from our own distribution server

  ```sh
  sudo -u mobilizon mkdir /var/lib/mobilizon/timezones
  sudo -u mobilizon curl -L 'https://packages.joinmobilizon.org/tz_world/timezones-geodata.dets' -o /var/lib/mobilizon/timezones/timezones-geodata.dets
  ```

In both cases, ~700Mio of disk will be used. You may use the following configuration to specify where the data is expected if you decide to change it from the default location (`/var/lib/mobilizon/timezones`) :
```elixir
config :tz_world, data_dir: "/some/place"
```

### Source install

You need to download the data :
* either raw from Github, but **requires an extra ~1Gio of memory** to process the data

  ```sh
  sudo -u mobilizon mkdir /var/lib/mobilizon/timezones
  sudo -u mobilizon mix mobilizon.tz_world.update
  ```

* either already processed from our own distribution server

  ```sh
  sudo -u mobilizon mkdir /var/lib/mobilizon/timezones
  sudo -u mobilizon curl -L 'https://packages.joinmobilizon.org/tz_world/timezones-geodata.dets' -o /var/lib/mobilizon/timezones/timezones-geodata.dets
  ```

In both cases, ~700Mio of disk will be used. You may use the following configuration to specify where the data is expected:
```elixir
config :tz_world, data_dir: "/some/place"
```

## Exports folder

Create the folder for default CSV export:

```sh
sudo -u mobilizon mkdir -p /var/lib/mobilizon/uploads/exports/csv
```

This path can be configured, see [the dedicated docs page about this](https://docs.joinmobilizon.org/administration/configure/exports/).
Files in this folder are temporary and are cleaned once an hour.

## New optional dependencies

These are optional, installing them will allow Mobilizon to export to PDF and ODS as well. Mobilizon 2.0 allows to export the participant list, but more is planned.
### Docker
Everything is included in our Docker image.
### Release and source install

New optional Python dependencies:
* `Python` >= 3.6
* `weasyprint` for PDF export (with [a few extra dependencies](https://doc.courtbouillon.org/weasyprint/stable/first_steps.html))
* `pyexcel-ods3` for ODS export (no extra dependencies)

Both can be installed through pip. You need to enable and configure exports for PDF and ODS in the configuration afterwards. Read [the dedicated docs page about this](https://docs.joinmobilizon.org/administration/configure/exports/).

# Upgrading from 1.0 to 1.1

The 1.1 version of Mobilizon brings Elixir releases support. An Elixir release is a self-contained directory that contains all of Mobilizon's code (front-end and backend), it's dependencies, as well as the Erlang Virtual Machine and runtime (only the parts you need). As long as the release has been assembled on the same OS and architecture, it can be deploy and run straight away. [Read more about releases](https://elixir-lang.org/getting-started/mix-otp/config-and-releases.html#releases).

## Comparison
Migrating to releases means:
* You only get a precompiled binary, so you avoid compilation times when updating
* No need to have Elixir/NodeJS installed on the system
* Code/data/config location is more common (/opt, /var/lib, /etc)
* More efficient, as only what you need from the Elixir/Erlang standard libraries is included and all of the code is directly preloaded
* You can't hardcode modifications in Mobilizon's code

Staying on source releases means:
* You need to recompile everything with each update
* Compiling frontend and backend has higher system requirements than just running Mobilizon
* You can change things in Mobilizon's code and recompile right away to test changes

## Releases
If you want to migrate to releases, [we provide a full guide](https://docs.joinmobilizon.org/administration/upgrading/source_to_release/). You may do this at any time.

## Source install
To stay on a source release, you just need to check the following things:
* Rename your configuration file `config/prod.secret.exs` to `config/runtime.exs`.
* If your config file includes `server: true` under `Mobilizon.Web.Endpoint`, remove it.
    ```diff
    config :mobilizon, Mobilizon.Web.Endpoint,
    - server: true,
    ```
* The uploads default directory is now `/var/lib/mobilizon/uploads`. To keep it in the previous `uploads/` directory, just add the following line to `config/runtime.exs`:
  ```elixir
  config :mobilizon, Mobilizon.Web.Upload.Uploader.Local, uploads: "uploads"
  ```
  Or you may use any other directory where the `mobilizon` user has write permissions.
* The GeoIP database default directory is now `/var/lib/mobilizon/geo/GeoLite2-City.mmdb`. To keep it in the previous `priv/data/GeoLite2-City.mmdb` directory, just add the following line to `config/runtime.exs`:
  ```elixir
  config :geolix, databases: [
    %{
      id: :city,
      adapter: Geolix.Adapter.MMDB2,
      source: "priv/data/GeoLite2-City.mmdb"
    }
  ]
  ```
  Or you may use any other directory where the `mobilizon` user has read permissions.