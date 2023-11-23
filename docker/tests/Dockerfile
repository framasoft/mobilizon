FROM elixir:latest
LABEL maintainer="Thomas Citharel <thomas.citharel@framasoft.org>"

ENV REFRESHED_AT=2023-11-20
RUN apt-get update -yq && apt-get install -yq ca-certificates build-essential inotify-tools postgresql-client git curl gnupg xvfb libgtk-3-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 cmake exiftool python3-pip python3-setuptools
RUN mkdir -p /etc/apt/keyrings && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && apt-get update && apt-get install nodejs -yq
RUN npm install -g wait-on
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN mix local.hex --force && mix local.rebar --force
RUN pip3 --no-cache-dir install -Iv weasyprint pyexcel_ods3
RUN curl https://dbip.mirror.framasoft.org/files/dbip-city-lite-latest.mmdb --output GeoLite2-City.mmdb -s && mkdir -p /usr/share/GeoIP && mv GeoLite2-City.mmdb /usr/share/GeoIP/
