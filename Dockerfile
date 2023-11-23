FROM elixir:1.15-alpine

RUN apk add --no-cache inotify-tools postgresql-client file make gcc libc-dev argon2 imagemagick cmake build-base libwebp-tools bash ncurses git python3 npm

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app

EXPOSE 4000
EXPOSE 5173
