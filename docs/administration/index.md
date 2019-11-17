# Install

## Pre-requisites

* A Linux machine with **root access**
* A **domain name** (or subdomain) for the Mobilizon server, e.g. `example.net`
* An **SMTP server** to deliver emails 

!!! tip
    You can also install Mobilizon [with Docker](docker.md).

## Dependencies

Mobilizon requires Elixir, NodeJS and PostgreSQL among other things.  

Installing dependencies depends on the system you're using. Follow the steps of the [dependencies guide](dependencies.md).

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

Then compile these dependencies and Mobilizon (this can take a few minutes)

```bash
mix compile
```

Go into the `js/` directory

```bash
cd js
```

and install the Javascript dependencies

```bash
yarn install
```

Finally, we can build the front-end (this can take a few seconds)
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
mix mobilizon.instance gen
```

This will ask you questions about your instance and generate a `.env.prod` file.


### Migration

Run database migrations: `mix ecto.migrate`. You will have to do this again after most updates.

!!! tip
    If some migrations fail, it probably means you're not using a recent enough version of PostgreSQL, or that you haven't installed the required extensions.

## Services

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
systemctl enable --now mobilizon.service
```

It will run Mobilizon and enable startup on boot. You can follow the logs with

```bash
sudo journalctl -fu mobilizon.service
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

Edit the file `/etc/nginx/sites-available` and adapt it to your own configuration.

Test the configuration with `sudo nginx -t` and reload nginx with `systemctl reload nginx`.
