# Maintenance tasks

## Installation

Generates new configuration files.

!!! warning
    This command generates configuration for your Mobilizon instance and should be run only once when installing. 

If any options are left unspecified, you will be prompted interactively.

```bash
mix mobilizon.instance gen [<options>]
```

### Options
* `-f`, `--force` Whether to erase existing files
* `-o`, `--output PATH` The path to output the `.env` file. Defaults to `.env.production`.
* `--output_psql PATH` The path to output the SQL script. Defaults to `setup_db.psql`.
* `--domain DOMAIN` The instance's domain
* `--instance_name INSTANCE_NAME` The instance's name
* `--admin_email ADMIN_EMAIL` The administrator's email
* `--dbhost HOSTNAME` The database hostname of the PostgreSQL database to use
* `--dbname DBNAME` The name of the database to use 
* `--dbuser DBUSER` The database user (aka role) to use for the database connection 
* `--dbpass DBPASS` The database user's password to use for the database connection 
* `--dbport DBPORT` The database port

## Depreciated commands

### move_participant_stats

Task to move participant stats directly on the `event` table (so there's no need to count event participants each time).
This task should **only be run once** when migrating from `v1.0.0-beta.1` to `v1.0.0-beta.2`.

This task will be removed in version `v1.0.0-beta.3`.

```bash
mix mobilizon.move_participant_stats
```

### setup_search

Task to setup search for existing events.

This task should **only be run once** when migrating from `v1.0.0-beta.1` to `v1.0.0-beta.2`.

This task will be removed in version `v1.0.0-beta.3`.

```bash
mix mobilizon.setup_search
```
