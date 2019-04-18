FROM bitwalker/alpine-elixir:latest

RUN apk add inotify-tools postgresql-client yarn

RUN mix local.hex --force && mix local.rebar --force

COPY docker/entrypoint.sh /bin/entrypoint

WORKDIR /app

EXPOSE 4000 4001 4002
