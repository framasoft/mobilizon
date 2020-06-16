# Configuration

Basic Mobilizon configuration can be handled through the Admin panel in the UI.

Core mobilizon configuration must be managed into the `config/prod.secret.exs` file.
After performing changes to this file, you have to recompile the mobilizon app with:
```bash
MIX_ENV=prod mix compile
```
and then restart the Mobilizon service:
```
systemctl restart mobilizon
```
