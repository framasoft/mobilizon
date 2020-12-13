# First build the application assets
FROM node:alpine as assets

RUN apk add --no-cache python build-base libwebp-tools bash imagemagick ncurses

COPY js .
RUN yarn install \
    && yarn run build

# Then, build the application binary
FROM elixir:alpine AS builder

RUN apk add --no-cache build-base git cmake

COPY mix.exs mix.lock ./
ENV MIX_ENV=prod
RUN mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get

COPY lib ./lib
COPY priv ./priv
COPY config ./config
COPY rel ./rel
COPY docker/production/releases.exs ./config/
COPY --from=assets ./priv/static ./priv/static

RUN mix phx.digest \
    && mix release

# Finally setup the app
FROM alpine

RUN apk add --no-cache openssl ncurses-libs file postgresql-client

RUN mkdir -p /app/uploads && chown nobody:nobody /app/uploads

USER nobody
EXPOSE 4000

COPY --from=builder --chown=nobody:nobody _build/prod/rel/mobilizon ./
COPY docker/production/docker-entrypoint.sh ./

ENTRYPOINT ["./docker-entrypoint.sh"]
