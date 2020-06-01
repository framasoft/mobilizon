# Development

Clone the repository:

```bash tab="HTTPS"
git clone https://framagit.org/framasoft/mobilizon && cd mobilizon
```

```bash tab="SSH"
git clone git@framagit.org:framasoft/mobilizon.git && cd mobilizon
```

Run Mobilizon:

  * with Docker and Docker-Compose (**Recommended**)
  * without Docker and Docker-Compose (This involves more work on your part, use Docker and Docker-Compose if you can)

## With Docker

  * Install [Docker](https://docs.docker.com/install/#supported-platforms) and [Docker-Compose](https://docs.docker.com/compose/install/) for your system.
  * Run `make start` to build, then launch a database container and an API container.
  * Follow the progress of the build with `docker-compose logs -f`.
  * Access `localhost:4000` in your browser once the containers are fully built and launched.

## Without Docker

  * Install dependencies:
    * [Elixir (and Erlang)](https://elixir-lang.org/install.html)
    * PostgreSQL >= 9.6 with PostGIS
    * [Install NodeJS](https://nodejs.org/en/download/) (we guarantee support for the latest LTS and later) ![](https://img.shields.io/badge/node-%3E%3D%2012.0+-brightgreen.svg)
  * Start services:
    * Start postgres
  * Setup services:
    * Make sure the postgis extension is installed on your system.
    * Create a postgres user with database creation capabilities, using the
      following: `createuser -d -P mobilizon` and set `mobilizon` as the password.
  * Install packages
    * Fetch backend Elixir dependencies with `mix deps.get`.
    * Go into the `cd js` directory, `yarn install` and then back `cd ../`
  * Setup
    * Create your database with `mix ecto.create`.
    * Create the postgis extension on the database with a postgres user that has
      superuser capabilities: `psql mobilizon_dev`

      ``` create extension if not exists postgis; ```

    * Run migrations: `mix ecto.migrate`.
    * Generate a Guardian secret with `mix guardian.gen.secret`:
      ```bash
      $ mix guardian.gen.secret
      $ TTRcgYH/Y0rk8ph5fqExVWRWjK03cqymfTa70leljmLMsBChtm+6MM+pRrL76Io3
      ```
    * Create a `config/dev.secret.exs` file and add the Guardian config:

      ```elixir
      import Config

      config :mobilizon, Mobilizon.Web.Auth.Guardian,
        secret_key: "TTRcgYH/Y0rk8ph5fqExVWRWjK03cqymfTa70leljmLMsBChtm+6MM+pRrL76Io3"

      ```
    * Generate your first user with the `mix mobilizon.users.new` task

      ```bash
        $ mix mobilizon.users.new john.doe@localhost.com
          An user has been created with the following information:
            - email: john.doe@localhost.com
            - password: r/EKpKr5o7ngQY+r
            - Role: user
          The user will be prompted to create a new profile after login for the first time.
      ```
  * Start Phoenix endpoint with `mix phx.server`. The client development server will also automatically be launched and will reload on file change.

Now you can visit [`localhost:4000`](http://localhost:4000) in your browser
and see the website (server *and* client) in action.

## FAQ

### Issues with argon2 when creating users.

This is because you installed deps through Docker and are now using Mobilizon without it, or the other way around. Just `rm -r deps/argon2_elixir` and trigger `mix deps.get` again.