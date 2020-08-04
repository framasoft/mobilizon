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
* `-o`, `--output PATH` The path to output the `prod.secret.exs` file. Defaults to `config/prod.secret.exs`.
* `--output-psql PATH` The path to output the SQL script. Defaults to `setup_db.psql`.
* `--domain DOMAIN` The instance's domain
* `--instance-name INSTANCE_NAME` The instance's name
* `--admin-email ADMIN_EMAIL` The administrator's email
* `--dbhost HOSTNAME` The database hostname of the PostgreSQL database to use
* `--dbname DBNAME` The name of the database to use 
* `--dbuser DBUSER` The database user (aka role) to use for the database connection 
* `--dbpass DBPASS` The database user's password to use for the database connection 
* `--dbport DBPORT` The database port
