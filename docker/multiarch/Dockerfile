ARG IMAGE="elixir:1.15"

FROM ${IMAGE} as build
SHELL ["/bin/bash", "-c"]
ENV MIX_ENV prod
# ENV LANG en_US.UTF-8
ARG APP_ASSET

# Fix qemu segfault on arm64
# See https://github.com/plausible/analytics/pull/2879 and https://github.com/erlang/otp/pull/6340
ARG ERL_FLAGS=""
ENV ERL_FLAGS=$ERL_FLAGS

# Set the right versions
ENV ELIXIR_VERSION latest
ENV ERLANG_VERSION latest
ENV NODE_VERSION 20

# Install system dependencies
RUN apt-get update -yq && apt-get install -yq build-essential cmake postgresql-client git curl gnupg unzip exiftool webp imagemagick gifsicle
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# # Install Node
# RUN curl -sL https://deb.nodesource.com/setup_16.x | bash && apt-get install nodejs -yq

# Install build tools
RUN source /root/.bashrc && \
    mix local.rebar --force && \
    mix local.hex -if-missing --force

RUN mkdir /mobilizon
COPY ./ /mobilizon
WORKDIR /mobilizon

# # Build front-end
# RUN npm install
# RUN npm run build

# Elixir release
RUN source /root/.bashrc && \
    mix deps.get --only prod && \
    mix compile  && \
    mix phx.digest.clean --all && \
    mix phx.digest && \
    mix release --path release/mobilizon && \
    cd release/mobilizon && \
    ln -s lib/mobilizon-*/priv priv && \
    cd ../../

# Make a release archive
RUN tar -zcf /mobilizon/${APP_ASSET} -C release mobilizon
