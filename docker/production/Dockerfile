FROM elixir:slim

# Install dependencies, NodeJS, YARN & clean apt
RUN apt update \
 && apt -y dist-upgrade \
 && apt -y install build-essential \
  curl \
  wget \
  unzip \
  vim \
  openssl \
  git \
  cmake \
  imagemagick \
  webp \
  gifsicle \
  jpegoptim \
  optipng  \
  pngquant \
  postgresql-client \
 && curl -sL https://deb.nodesource.com/setup_12.x | bash - \
 && apt -y install nodejs \
 && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
 && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
 && apt -y update && apt -y install yarn \
 && apt -y clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add mobilizon user
RUN groupadd -r mobilizon \
    && useradd -r -g mobilizon -m mobilizon

USER mobilizon

# ENV
ENV MIX_ENV=prod

# PORT
EXPOSE 4000

# Copy repo
COPY . /app
WORKDIR /app

# Compile dependencies, Mobilizon and build front-end
RUN mix local.hex --force && mix local.rebar --force \
 && HEX_HTTP_CONCURRENCY=4 HEX_HTTP_TIMEOUT=60 mix do deps.get, compile \
 && cd js && NODE_BUILD_MEMORY=2024 yarn install && NODE_BUILD_MEMORY=2024 yarn run build \
 # free space
 && rm -rf js doc deps docs support \
 && rm -rf /home/mobilizon/.cache/* \
 # copy config secret env based file
 && cp docker/production/prod.secret config/ \
 # set start script mod
 && chmod +x /app/docker/production/start.sh

CMD /app/docker/production/start.sh

## start.sh:
# !/bin/bash
# mix ecto.migrate
# mix phx.server
