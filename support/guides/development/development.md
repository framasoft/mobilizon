# Development

Clone the repository:
```bash
# With HTTPS
git clone https://framagit.org/framasoft/mobilizon && cd mobilizon

# With SSH
git clone git@framagit.org:framasoft/mobilizon.git && cd mobilizon
```

Run Mobilizon:
  * with Docker and Docker-Compose (**Recommended**)
  * without Docker and Docker-Compose (This involves more work on your part, use Docker and Docker-Compose if you can)

## With Docker and Docker-Compose

  * Install [Docker](https://docs.docker.com/install/#supported-platforms) and [Docker-Compose](https://docs.docker.com/compose/install/) for your system.
  * Run `make start` to build, then launch a database container and an API container.
  * Follow the progress of the build with `docker-compose logs -f`.
  * Access `localhost:4000` in your browser once the containers are fully built and launched.

## Without Docker and Docker-Compose

  * Install dependencies:
    * Elixir (and Erlang) by following the instructions at [https://elixir-lang.github.io/install.html](https://elixir-lang.github.io/install.html)
    * [PostgreSQL]() with PostGIS
    * Install NodeJS (we guarantee support for the latest LTS and later) ![](https://img.shields.io/badge/node-%3E%3D%2010.0+-brightgreen.svg)
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
  * Start Phoenix endpoint with `mix phx.server`. The client development server will also automatically be launched and will reload on file change.

Now you can visit [`localhost:4000`](http://localhost:4000) in your browser
and see the website (server *and* client) in action.