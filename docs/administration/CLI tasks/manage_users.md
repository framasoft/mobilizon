# Manage users

!!! tip "Environment"
    You need to run these commands with the appropriate environment loaded


## List all available commands 
```bash
mix mobilizon.users
```

## Create a new user

```bash
mix mobilizon.users.new <email> [<options>]
```

### Options

* `--password <password>`/ `-p <password>` - the user's password. If this option is missing, a password will be generated randomly.
* `--moderator` - make the user a moderator
* `--admin` - make the user an admin

## Show an user's details

Displays if the user has confirmed their email, if they're a moderator or an admin and their profiles.

```bash
mix mobilizon.users.show <email>
```

## Modify an user

```bash
mix mobilizon.users.modify <email>
```

### Options

* `--email <email>` - the user's new email
* `--password <password>` - the user's new password.
* `--user` - make the user a regular user
* `--moderator` - make the user a moderator
* `--admin` - make the user an admin
* `--enable` - enable the user
* `--disable` - disable the user

## Delete an user

```bash
mix mobilizon.users.delete <email>
```

### Options

* `--assume_yes`/`-y` Don't ask for confirmation