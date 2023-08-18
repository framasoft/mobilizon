FROM elixir:latest
LABEL maintainer="Thomas Citharel <tcit@tcit.fr>"

ENV REFRESHED_AT=2023-08-17
RUN apt-get update -yq && apt-get install -yq build-essential inotify-tools postgresql-client git curl gnupg xvfb libgtk-3-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 cmake exiftool python3-pip python3-setuptools
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash && apt-get install nodejs -yq
RUN npm install -g yarn wait-on
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN mix local.hex --force && mix local.rebar --force
RUN pip3 install -Iv weasyprint pyexcel_ods3
RUN curl https://dbip.mirror.framasoft.org/files/dbip-city-lite-latest.mmdb --output GeoLite2-City.mmdb -s && mkdir -p /usr/share/GeoIP && mv GeoLite2-City.mmdb /usr/share/GeoIP/
