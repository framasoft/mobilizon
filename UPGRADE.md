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