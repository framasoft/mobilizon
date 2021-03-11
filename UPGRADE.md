# Upgrading from 1.0 to 1.1

The 1.1 version of Mobilizon brings Elixir releases support. An Elixir release is a self-contained directory that contains all of Mobilizon's code (front-end and backend), it's dependencies, as well as the Erlang Virtual Machine and runtime (only the parts you need). As long as the release has been assembled on the same OS and architecture, it can be deploy and run straight away. [Read more about releases](https://elixir-lang.org/getting-started/mix-otp/config-and-releases.html#releases).

Migrating to releases means:
* You only get a precompiled binary, so you avoid compilation times when updating
* Code/data/config location is more common (/opt, /var/lib, /etc)
* More efficient, as only what you need from the Elixir/Erlang standard libraries is included and all of the code is directly preloaded
* You can't hardcode modifications in Mobilizon's code

Staying on source releases means:
* You need to recompile everything with each update
* You can change things in Mobilizon's code and recompile right away

If you want to migrate to releases, [we provide a guide](https://docs.joinmobilizon.org/administration/upgrading/source_to_release/).