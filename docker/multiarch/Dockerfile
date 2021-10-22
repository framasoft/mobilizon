FROM elixir as build
SHELL ["/bin/bash", "-c"]
ENV MIX_ENV prod
# ENV LANG en_US.UTF-8
ARG APP_ASSET

# Set the right versions
ENV ELIXIR_VERSION latest
ENV ERLANG_VERSION latest
ENV NODE_VERSION 16

# Install system dependencies
RUN apt-get update -yq && apt-get install -yq build-essential cmake postgresql-client git curl gnupg unzip exiftool webp imagemagick gifsicle
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# # Install Node & yarn
# RUN curl -sL https://deb.nodesource.com/setup_16.x | bash && apt-get install nodejs -yq
# RUN npm install -g yarn

# Install build tools
RUN source /root/.bashrc && \
    mix local.rebar --force && \
    mix local.hex -if-missing --force

RUN mkdir /mobilizon
COPY ./ /mobilizon
WORKDIR /mobilizon

# # Build front-end
# RUN yarn --cwd "js" install --frozen-lockfile
# RUN yarn --cwd "js" run build

# Elixir release
RUN source /root/.bashrc && \
    mix deps.get --only prod && \
    mix compile  && \
    mix phx.digest.clean --all && \
    mix release --path release/mobilizon && \
    cd release/mobilizon && \
    ln -s lib/mobilizon-*/priv priv && \
    cd ../../

# Make a release archive
RUN tar -zcf /mobilizon/${APP_ASSET} -C release mobilizon
