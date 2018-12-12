# Mobilizon

Your federated organization and mobilization platform. Gather people with a convivial, ethical, and emancipating tool.

## Development

### Manual

#### Server

  * Install dependencies:
    * Elixir (and Erlang) by following the instructions at [https://elixir-lang.github.io/install.html](https://elixir-lang.github.io/install.html)
    * Fetch backend Elixir dependencies with `mix deps.get`.
    * PostgreSQL
  * Start services:
    * Start postgres
  * Setup services:
    * Make sure the postgis extension is installed on your system.
    * Create a postgres user with database creation capabilities, using the
      following: `createuser -d -P elixir` and set `elixir` as the password.
    * Create your database with `mix ecto.create`.
    * Create the postgis extension on the database with a postgres user that has
      superuser capabilities: `psql mobilizon_dev`

      ``` create extension if not exists postgis; ```

    * Run migrations: `mix ecto.migrate`.
  * Start Phoenix endpoint with `mix phx.server`.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser
and see the website (server *and* client) in action.

#### Client

If you plan to specifically change the client side (frontend), do the following
once the server is running:

  * Install the NodeJS (we guarantee support for the latest LTS and later) ![](https://img.shields.io/badge/node-%3E%3D%2010.0+-brightgreen.svg)
  * Change directory to `js/` and do:
    * Install JavaScript package dependencies: `npm install`.
    * Run the developement server in watch mode: `npm run dev`. This will open a
      browser on [`localhost:8080`](http://localhost:8080) that gets
      automatically reloaded on change.

### Docker

Just run `docker-compose up -d` to start a database container, an API container and the front-end dev container running on localhost.

## Learn more

  * Official website: https://joinmobilizon.org/
  * Source: https://framagit.org/framasoft/mobilizon
