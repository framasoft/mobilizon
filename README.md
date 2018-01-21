[![pipeline status](https://framagit.org/tcit/eventos/badges/master/pipeline.svg)](https://framagit.org/tcit/eventos/commits/master)
[![coverage report](https://framagit.org/tcit/eventos/badges/master/coverage.svg)](https://framagit.org/tcit/eventos/commits/master)

# Eventos

## Development

### Server

  * Start postgres and make sure the postgis extension is installed.
  * Create a postgres user with database creation capabilities, using the
    following: `createuser -d -P elixir` and set `elixir` as the password.
  * Fetch dependencies with `mix deps.get`.
  * Create your database with `mix ecto.create`.
  * Create the postgis extension on the database with a postgres user that has
    superuser capabilities: `psql eventos_dev`

    ``` create extension if not exists postgis; ```

  * Run migrations: `mix ecto.migrate`.
  * Start Phoenix endpoint with `mix phx.server`.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser
and see the website (server *and* client) in action.

### Client

If you plan to specifically change the client side (frontend), do the following
once the server is running:

  * Change directory to `js/`.
  * Install JavaScript package dependencies: `npm install`.
  * Run the developement server in watch mode: `npm run dev`. This will open a
    browser on [`localhost:8080`](http://localhost:8080) that gets
    automatically reloaded on change.

## Production

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
