# Dependencies

## Debian / Ubuntu and derivatives

This documentation is appropriate for Debian 10 (Buster) and Ubuntu 18.04 LTS.

### Security

We advise to make sure your webserver is secure enough.
For instance you can require authentication through SSH keys and not passwords, install Fail2Ban to block repeated login attempts and block unused ports by installing and configuring a firewall.

### Upgrade system

Just to be sure your system is up-to-date before doing anything else:

```bash
sudo apt update
sudo apt dist-upgrade
```

### Basic tools
We begin by making sure some basic tools are installed: 

```bash
sudo apt install build-essential curl unzip vim openssl git cmake
```

### Web server
We only officially support nginx.

```bash
sudo apt install nginx
```

### HTTPS Certificates
Then we need to install [certbot](https://certbot.eff.org/), a tool to ask for free Let's Encrypt HTTPS certificates.
 
```bash
sudo apt install certbot
```

You can use certbot with web server plugins or manually. See [Certbot's documentation](https://certbot.eff.org/instructions).


### NodeJS
We install the latest NodeJS version by adding NodeSource repos and installing NodeJS:

Head over to [this page](https://github.com/nodesource/distributions/blob/master/README.md#table-of-contents) and follow the instructions for `Node.js v12.x`.

!!! info
    Unless stated otherwise, Mobilizon always supports only the latest LTS version of NodeJS.
    
!!! tip
    NodeSource repos only gives updates for a specific version of NodeJS (it doesn't upgrade itself to a new major version). When a new major version of NodeJS is released, you need to remove the old repo and add the new one. 

### Yarn
Mobilizon uses [Yarn](https://yarnpkg.com/) to manage NodeJS packages, so we need to install it as well.

Follow the instructions on [this page](https://yarnpkg.com/en/docs/install#debian-stable) to add Yarn's repository and install it.

!!! info
    It is also possible to install `yarn` directly with `npm`: 
    ```bash
    npm install -g yarn
    ```.
    You need to make sure npm's binary packages folder in your `$PATH` afterwards to use `yarn`.

### Erlang and Elixir

The packages from Debian or Ubuntu are badly packaged and often out of date, so we need to add one final source repository.

Follow the instructions for Ubuntu/Debian on [this page](https://elixir-lang.org/install.html#unix-and-unix-like) to add Erlang Solutions repo and install Erlang and Elixir.

!!! tip
    The Erlang package also wants to install an add-on for Emacs for some reason (but it doesn't install Emacs). If you see a warning, nothing to worry about. 

### PostgreSQL and PostGIS

Mobilizon uses the [PostgreSQL](https://www.postgresql.org) database, and the PostgreSQL [Postgis](https://postgis.net) extension to store geographical data into PostgreSQL.

```bash
sudo apt install postgresql postgresql-contrib postgis
```

After that we can enable and start the PostgreSQL service. 
```
sudo systemctl --now enable postgresql
```

### Misc

We need the following tools to handle and optimize pictures that are uploaded on Mobilizon.

```bash
sudo apt install imagemagick
```

The following packages are optional, Mobilizon can run without them.

```bash
sudo apt install webp gifsicle jpegoptim optipng pngquant
```

Once finished, let's [head back to the install guide](index.md).

## Arch Linux

Run the following command to install all at once:
```bash
sudo pacman -S nodejs postgresql openssl git wget unzip base-devel yarn nginx elixir postgis imagemagick
```

Now that dependencies are installed, before running Mobilizon you should start PostgreSQL:
```
sudo systemctl --now enable postgresql
```

Once finished, let's [head back to the install guide](index.md).

## Other distributions

Feel free to update this file in a pull request!
