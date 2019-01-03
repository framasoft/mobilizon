FROM elixir:1.7

RUN apt-get update && apt-get install -y build-essential inotify-tools postgresql-client

RUN mix local.hex --force && mix local.rebar --force

COPY docker/entrypoint.sh /bin/entrypoint

WORKDIR /app

EXPOSE 4000 4001 4002