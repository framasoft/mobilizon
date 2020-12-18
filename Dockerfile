FROM bitwalker/alpine-elixir:latest

RUN apk add inotify-tools postgresql-client yarn file
RUN apk add --no-cache make gcc libc-dev argon2 imagemagick cmake build-base

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app

EXPOSE 4000
