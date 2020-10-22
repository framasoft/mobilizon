# Build and deploy Mobilizon with docker

You will need to :
- build the image
- tune the environment file
- use docker-compose to run the service

## Build the image

    git clone https://forge.tedomum.net/tedomum/mobilizon
    cd mobilizon
    docker build -t mobilizon -f docker/production/Dockerfile .

## Update the env file

    cd docker/production/
    cp env.example .env

Edit the `.env` content with your own settings.

You can generate `MOBILIZON_INSTANCE_SECRET_KEY_BASE` and `MOBILIZON_INSTANCE_SECRET_KEY` with:

    gpg --gen-random --armor 1 50

## Run the service

Start by initializing and running the database:

    docker-compose up -d db

Instanciate required Postgres extensions:

    docker-compose exec db psql -U <username>
    # CREATE EXTENSION pg_trgm;
    # CREATE EXTENSION unaccent;


Then run migrations:

    docker-compose run --rm mobilizon eval Mobilizon.Cli.migrate

Finally, run the application:

    docker-compose up -d mobilizon

## Update the service

Pull the latest image, then run the migrations:

    docker-compose pull mobilizon
    docker-compose run --rm mobilizon eval Mobilizon.Cli.migrate

Finally, update the service:

    docker-compose up -d mobilizon
