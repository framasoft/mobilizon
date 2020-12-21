FROM bitwalker/alpine-elixir:latest

RUN apk add --no-cache inotify-tools postgresql-client yarn file make gcc libc-dev argon2 imagemagick cmake build-base libwebp-tools bash ncurses

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app

EXPOSE 4000
