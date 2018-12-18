FROM elixir:latest

RUN apt-get update -yq && apt-get install -yq build-essential inotify-tools postgresql-client git curl gnupg
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash && apt-get install nodejs -yq
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN curl http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz --output GeoLite2-City.tar.gz -s && tar zxf GeoLite2-City.tar.gz && mkdir -p /usr/share/GeoIP && mv GeoLite2-City_*/GeoLite2-City.mmdb /usr/share/GeoIP/GeoLite2-City.mmdb