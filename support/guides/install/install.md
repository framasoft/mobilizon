# Install

## Dependencies

Follow the steps of the [dependencies guide](dependencies.html)

## Database

Create the production database and a mobilizon user inside PostgreSQL:

```bash
sudo -u postgres createuser -P mobilizon
sudo -u postgres createdb -O mobilizon mobilizon_prod
```

Then enable extensions PeerTube needs:

```bash
sudo -u postgres psql -c "CREATE EXTENSION postgis;" mobilizon_prod
sudo -u postgres psql -c "CREATE EXTENSION pg_trgm;" mobilizon_prod
sudo -u postgres psql -c "CREATE EXTENSION unaccent;" mobilizon_prod
```


## MobiliZon user

Create a `mobilizon` user with `/home/mobilizon` home:
```bash
sudo adduser --disabled-login mobilizon
sudo -i -u mobilizon
```

**On FreeBSD**

```bash
sudo pw useradd -n mobilizon -d /home/mobilizon -s /usr/local/bin/bash -m
sudo passwd mobilizon
```

You can now fetch the code with git:
```bash
git clone https://framagit.org/framasoft/mobilizon live && cd live
```

## Configuration

### Backend

Install Elixir dependencies 

```bash
mix deps.get
```

Configure your instance with

```bash
mix mobilizon.instance gen
```

This will ask you questions about your instance and generate an `.env.prod` file.

### Migration
 
Run database migrations: `mix ecto.migrate`. You will have to do this again after most updates.

> If some migrations fail, it probably means you're not using a recent enough version of PostgreSQL,
or that you didn't installed [the required extensions](#database). 
  
### Front-end

Go into the `js/` directory

```bash
cd js/
```
and install the Javascript dependencies
 
```bash
npm install
```

Finally, build the front-end with 
```bash
npm run build
```
  
### Testing

Go back to the previous directory
 
```bash
cd ../
```

Now try to run the server 

```bash
mix phx.server
```

It runs on port 4000.


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

It will run MobiliZon and enable startup on boot. You can follow the logs with 

```bash
sudo journalctl -fu mobilizon.service
```

