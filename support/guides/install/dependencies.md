# Dependencies


- [Debian / Ubuntu and derivatives](#debian--ubuntu-and-derivatives)
- [Arch Linux](#arch-linux)
- [Other distributions](#other-distributions)

## Debian / Ubuntu and derivatives
  1. On a fresh Debian/Ubuntu, as root user, install basic utility programs needed for the installation

```
sudo apt install curl sudo unzip vim
```

  2. It would be wise to disable root access and to continue this tutorial with a user with sudoers group access
  3. Install certbot (choose instructions for nginx and your distribution):
     [https://certbot.eff.org/all-instructions](https://certbot.eff.org/all-instructions)
  4. Install NodeJS 10.x (current LTS):
     [https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions](https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions)
  5. Install yarn, and be sure to have [a recent version](https://github.com/yarnpkg/yarn/releases/latest):
     [https://yarnpkg.com/en/docs/install#linux-tab](https://yarnpkg.com/en/docs/install#linux-tab)
  6. Install Erlang and Elixir:
     [https://elixir-lang.org/install.html#unix-and-unix-like](https://elixir-lang.org/install.html#unix-and-unix-like)
  7. Install PostGIS:
     [https://postgis.net/install/](https://postgis.net/install/)
  8. Run:

```
sudo apt update
sudo apt install nginx postgresql postgresql-contrib openssl make git esl-erlang elixir postgis 
```

Now that dependencies are installed, before running Mobilizon you should start PostgreSQL:
```
sudo systemctl start postgresql
```

## Arch Linux

  1. Run:

```
sudo pacman -S nodejs postgresql openssl git wget unzip base-devel yarn nginx elixir postgis
```

Now that dependencies are installed, before running Mobilizon you should start PostgreSQL and Redis:
```
sudo systemctl start postgresql
```

## Other distributions

Feel free to update this file in a pull request!
