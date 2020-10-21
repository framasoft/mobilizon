# Install

!!! info "Docker"
    
    Docker production installation is not yet supported. See [issue #352](https://framagit.org/framasoft/mobilizon/issues/352).

## Pre-requisites

* A Linux machine with **root access**
* A **domain name** (or subdomain) for the Mobilizon server, e.g. `your-mobilizon-domain.com`
* An **SMTP server** to deliver emails

## Dependencies

Mobilizon requires Elixir, NodeJS and PostgreSQL among other things. Prefer to install Elixir and NodeJS from their official repositories instead of your distribution's packages.

Recommended versions:

* Elixir 1.8+
* NodeJS 12+
* PostgreSQL 11+

!!! important
    Installing dependencies depends on the system you're using. Follow the steps of the [dependencies guide](dependencies.md) and come back to this page when done.

## Setup

We're going to use a dedicated `mobilizon` user with `/home/mobilizon` home:
```bash
sudo adduser --disabled-login mobilizon
```

!!! tip

    On FreeBSD
    
    ``` bash
    sudo pw useradd -n mobilizon -d /home/mobilizon -s /usr/local/bin/bash -m 
    sudo passwd mobilizon
    ```

Then let's connect as this user:

```bash
sudo -i -u mobilizon
```

Let's start by cloning the repository in a directory named `live`:

```bash
git clone https://framagit.org/framasoft/mobilizon live && cd live
```


## Installing dependencies

Install Elixir dependencies

```bash
mix deps.get
```

!!! note
    When asked for `Shall I install Hex?` or `Shall I install rebar3?`, hit the enter key to confirm.

Then compile these dependencies and Mobilizon (this can take a few minutes, and can output all kinds of warnings, such as depreciation issues)

```bash
MIX_ENV=prod mix compile
```

Go into the `js/` directory

```bash
cd js
```

and install the Javascript dependencies

```bash
yarn install
```

Finally, we can build the front-end (this can take a few seconds).

!!! warning
    Building front-end can consume up to 2048MB of RAM by default. If it's too much or not sufficient for your setup, you can adjust the maximum memory used by prefixing the command with the following option:
    ```
    NODE_BUILD_MEMORY=1024
    ```
```bash
yarn run build
```

Let's go back to the main directory
```bash
cd ../
```

## Configuration

Mobilizon provides a command line tool to generate configuration

```bash
MIX_ENV=prod mix mobilizon.instance gen
```

This will ask you questions about your setup and your instance to generate a `prod.secret.exs` file in the `config/` folder, and a `setup_db.psql` file to setup the database.

### Database setup

The `setup_db.psql` file contains SQL instructions to create a PostgreSQL user and database with the chosen credentials and add the required extensions to the Mobilizon database.

Exit running as the mobilizon user (as it shouldn't have `root`/`sudo` rights) and execute in the `/home/mobilizon/live` directory:
```bash
sudo -u postgres psql -f setup_db.psql
```

It should output something like:
```
CREATE ROLE
CREATE DATABASE
You are now connected to database "mobilizon_prod" as user "postgres".
CREATE EXTENSION
CREATE EXTENSION
CREATE EXTENSION
```

Let's get back to our `mobilizon` user:
```bash
sudo -i -u mobilizon
cd live
```

!!! warning

    When it's done, don't forget to remove the `setup_db.psql` file.

### Database Migration

Run database migrations: 
```bash
MIX_ENV=prod mix ecto.migrate
```

!!! note

    Note the `MIX_ENV=prod` environment variable prefix in front of the command. You will have to use it for each `mix` command from now on.

You will have to do this again after most updates.

!!! tip
    If some migrations fail, it probably means you're not using a recent enough version of PostgreSQL, or that you haven't installed the required extensions.

## Services

We can quit using the `mobilizon` user again.

### Systemd

Copy the `support/systemd/mobilizon.service` to `/etc/systemd/system`.

```bash
sudo cp support/systemd/mobilizon.service /etc/systemd/system/
```

Reload Systemd to detect your new file

```bash
sudo systemctl daemon-reload
```

And enable the service

```bash
sudo systemctl enable --now mobilizon.service
```

It will run Mobilizon and enable startup on boot. You can follow the logs with

```bash
sudo journalctl -fu mobilizon.service
```

You should see something like this:
```
Running Mobilizon.Web.Endpoint with cowboy 2.8.0 at :::4000 (http)
Access Mobilizon.Web.Endpoint at https://your-mobilizon-domain.com
```

The Mobilizon server runs on port 4000 on the local interface only, so you need to add a reverse-proxy.

## Reverse proxy

### Nginx

Copy the file from `support/nginx/mobilizon.conf` to `/etc/nginx/sites-available`.

```bash
sudo cp support/nginx/mobilizon.conf /etc/nginx/sites-available
```

Then symlink the file into the `/etc/nginx/sites-enabled` directory.

```bash
sudo ln -s /etc/nginx/sites-available/mobilizon.conf /etc/nginx/sites-enabled/
```

Edit the file `/etc/nginx/sites-available/mobilizon.conf` and adapt it to your own configuration.

Test the configuration with `sudo nginx -t` and reload nginx with `sudo systemctl reload nginx`.

### Let's Encrypt

The nginx configuration template handles the HTTP-01 challenge with the webroot plugin:
```bash
sudo mkdir /var/www/certbot
```

Run certbot with (don't forget to adapt the command)
```bash
sudo certbot certonly --rsa-key-size 4096 --webroot -w /var/www/certbot/ --email your@email.com --agree-tos --text --renew-hook "/usr/sbin/nginx -s reload" -d your-mobilizon-domain.com
```

Then adapt the nginx configuration `/etc/nginx/sites-available/mobilizon.conf` by uncommenting certificate paths and removing obsolete blocks.

Finish by testing the configuration with `sudo nginx -t` and reloading nginx with `sudo systemctl reload nginx`.

You should now be able to load https://your-mobilizon-domain.com inside your browser.

## Creating your first user

Login back as the `mobilizon` system user:

```bash
sudo -i -u mobilizon
cd live
```

Create a new user:
```
 MIX_ENV=prod mix mobilizon.users.new "your@email.com" --admin --password "Y0urP4ssw0rd"
```

!!! danger
    Don't forget to prefix the command with an empty space so that the chosen password isn't kept in your shell history.

!!! tip
    You can ignore the `--password` option and Mobilizon will generate one for you.

See the [full documentation](./CLI tasks/manage_users.md#create-a-new-user) for this command.

You may now login with your credentials and discover Mobilizon. Feel free to explore [configuration documentation](./configure) as well.

## Optional tasks

### Geolocation databases

Mobilizon can use geolocation from MMDB format data from sources like [MaxMind GeoIP](https://dev.maxmind.com/geoip/geoip2/geolite2/) databases or [db-ip.com](https://db-ip.com/db/download/ip-to-city-lite) databases. This allows showing events happening near the user's location.

You will need to download the City database and put it into `priv/data/GeoLite2-City.mmdb`. Finish by restarting the `mobilizon` service.

Mobilizon will only show a warning at startup if the database is missing, but it isn't required.