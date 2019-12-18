# Relay

Manages remote relays

!!! tip "Environment"
    You need to run these commands with the appropriate environment loaded

## Make your instance follow a mobilizon instance

```bash
mix mobilizon.relay follow <relay_host>
```

Example: 
```bash
mix mobilizon.relay follow example.org
```

## Make your instance unfollow a mobilizon instance

```bash
mix mobilizon.relay unfollow <relay_host>
```

Example: 
```bash
mix mobilizon.relay unfollow example.org
```
