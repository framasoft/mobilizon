# Authentification

## LDAP

Use LDAP for user authentication.  When a user logs in to the Mobilizon instance, the email and password will be verified by trying to authenticate
(bind) to an LDAP server. If a user exists in the LDAP directory but there is no account with the same email yet on the Mobilizon instance then a new
Mobilizon account will be created (without needing email confirmation) with the same email as the LDAP email name.

!!! tip
    As Mobilizon uses email for login and LDAP bind is often done with account UID/CN, we need to start by searching for LDAP account matching with this email. LDAP search without bind is often disallowed, so you'll probably need an admin LDAP user.


Change authentification method:
```elixir
config :mobilizon,
       Mobilizon.Service.Auth.Authenticator,
       Mobilizon.Service.Auth.LDAPAuthenticator
```

LDAP configuration under `:mobilizon, :ldap`:

* `enabled`: enables LDAP authentication
* `host`: LDAP server hostname
* `port`: LDAP port, e.g. 389 or 636
* `ssl`: true to use SSL, usually implies the port 636
* `sslopts`: additional SSL options
* `tls`: true to start TLS, usually implies the port 389
* `tlsopts`: additional TLS options
* `base`: LDAP base, e.g. "dc=example,dc=com"
* `uid`: LDAP attribute name to authenticate the user, e.g. when "cn", the filter will be "cn=username,base"
* `require_bind_for_search` whether admin bind is required to perform search
* `bind_uid` the admin uid/cn for binding before searching
* `bind_password` the admin password for binding before searching

Example:

```elixir
config :mobilizon, :ldap,
  enabled: true,
  host: "localhost",
  port: 636,
  ssl: true,
  sslopts: [],
  tls: true,
  tlsopts: [],
  base: "ou=users,dc=example,dc=local",
  uid: "cn",
  require_bind_for_search: true,
  bind_uid: "admin_account",
  bind_password: "some_admin_password"
```

## OAuth

Mobilizon currently supports the following providers:

* [Discord](https://github.com/schwarz/ueberauth_discord)
* [Facebook](https://github.com/ueberauth/ueberauth_facebook)
* [Github](https://github.com/ueberauth/ueberauth_github)
* [Gitlab](https://github.com/mtchavez/ueberauth_gitlab) (including self-hosted)
* [Google](https://github.com/ueberauth/ueberauth_google)
* [Keycloak](https://github.com/Rukenshia/ueberauth_keycloak) (through OpenID Connect)
* [Twitter](https://github.com/Rukenshia/ueberauth_keycloak)

Support for [other providers](https://github.com/ueberauth/ueberauth/wiki/List-of-Strategies) can easily be added if requested.

!!! tip
    We advise to look at each provider's README file for eventual specific instructions.

You'll have to start by registering an app at the provider. Be sure to activate features like "Sign-in with" and "emails" scope, as Mobilizon needs users emails to register them.

Add the configured providers to configuration (you may find the appropriate scopes on the provider's API documentation):
```elixir
config :ueberauth,
       Ueberauth,
       providers: [
         gitlab: {Ueberauth.Strategy.Gitlab, [default_scope: "read_user"]},
         keycloak: {Ueberauth.Strategy.Keycloak, [default_scope: "email"]}
         # ...
       ]
```

In order for the « Sign-in with » buttons to be added on Register and Login pages, list your providers:
```elixir
config :mobilizon, :auth,
  oauth_consumer_strategies: [
    :gitlab,
    {:keycloak, "My corporate account"}
    # ...
  ]
```

!!! note
    If you use the `{:provider_id, "Some label"}` form, the label will be used inside the buttons on Register and Login pages.

Finally add the configuration for each specific provider. The Client ID and Client Secret are at least required:
```elixir
config :ueberauth, Ueberauth.Strategy.Facebook.OAuth,
  client_id: "some_numeric_id",
  client_secret: "some_secret"

keycloak_url = "https://some-keycloak-instance.org"

# Realm may be something else than master
config :ueberauth, Ueberauth.Strategy.Keycloak.OAuth,
  client_id: "some_id",
  client_secret: "some_hexadecimal_secret",
  site: keycloak_url,
  authorize_url: "#{keycloak_url}/auth/realms/master/protocol/openid-connect/auth",
  token_url: "#{keycloak_url}/auth/realms/master/protocol/openid-connect/token",
  userinfo_url: "#{keycloak_url}/auth/realms/master/protocol/openid-connect/userinfo",
  token_method: :post
```