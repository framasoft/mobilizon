# Development
Clone the repo, and start the project through Docker. You'll need both Docker and Docker-Compose.
```bash
git clone https://framagit.org/framasoft/mobilizon && cd mobilizon
make
```
## Manual

### Server

  * Install dependencies:
    
    * Elixir (and Erlang) by following the instructions at [https://elixir-lang.github.io/install.html](https://elixir-lang.github.io/install.html)
    * Fetch backend Elixir dependencies with `mix deps.get`.
    * [PostgreSQL]() with PostGIS
  * Start services:
    * Start postgres
  * Setup services:
    * Make sure the postgis extension is installed on your system.
    * Create a postgres user with database creation capabilities, using the
      following: `createuser -d -P mobilizon` and set `mobilizon` as the password.
    * Create your database with `mix ecto.create`.
    * Create the postgis extension on the database with a postgres user that has
      superuser capabilities: `psql mobilizon_dev`

      ``` create extension if not exists postgis; ```

    * Run migrations: `mix ecto.migrate`.
  * Start Phoenix endpoint with `mix phx.server`.

Now you can visit [`localhost:4000`](http://localhost:4000) in your browser
and see the website (server *and* client) in action.

### Client

If you plan to specifically change the client side (front-end), do the following
once the server is running:

  * Install NodeJS (we guarantee support for the latest LTS and later) ![](https://img.shields.io/badge/node-%3E%3D%2010.0+-brightgreen.svg)
  * Change directory to `js/` and do:
    * Install JavaScript package dependencies: `yarn install`.
    * Run the development server in watch mode: `yarn run dev`. This will open a
      browser at [`localhost:8080`](http://localhost:8080) that gets
      automatically reloaded on change.

## Docker
You need to install the latest supported [Docker](https://docs.docker.com/install/#supported-platforms) and [Docker-Compose](https://docs.docker.com/compose/install/) before using the Docker way of installing Mobilizon.

Just run :
```bash
make start
```
to start a database container, an API container and the front-end dev container running on localhost.
