FROM elixir:latest

RUN apt-get update -yq && apt-get install -yq build-essential inotify-tools postgresql-client git curl gnupg
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash && apt-get install nodejs -yq
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*