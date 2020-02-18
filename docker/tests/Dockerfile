FROM elixir:latest
LABEL maintainer="Thomas Citharel <tcit@tcit.fr>"

ENV REFRESHED_AT=2019-12-17
RUN apt-get update -yq && apt-get install -yq build-essential inotify-tools postgresql-client git curl gnupg xvfb libgtk-3-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 python3-pip
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash && apt-get install nodejs -yq
RUN npm install -g yarn wait-on
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN mix local.hex --force && mix local.rebar --force
RUN pip3 install mkdocs mkdocs-material pymdown-extensions pygments mkdocs-git-revision-date-localized-plugin
RUN curl https://dbip.mirror.framasoft.org/files/dbip-city-lite-latest.mmdb --output GeoLite2-City.mmdb -s && mkdir -p /usr/share/GeoIP && mv GeoLite2-City.mmdb /usr/share/GeoIP/
