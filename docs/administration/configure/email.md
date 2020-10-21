# Email

Mobilizon requires a SMTP server to deliver emails. Using 3rd-party mail providers (Mandrill, SendGrid, Mailjet, …) will be possible in the future.

## SMTP configuration

Mobilizon default settings assumes a SMTP server listens on `localhost`, port `25`. To specify a specific server and credentials, you can add the following section in your `prod.secret.exs` file and modify credentials to your needs.

```elixir
config :mobilizon, Mobilizon.Web.Email.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "localhost",
  hostname: "localhost",
  # usually 25, 465 or 587
  port: 25,
  username: nil,
  password: nil,
  # can be `:always` or `:never`
  tls: :if_available,
  allowed_tls_versions: [:tlsv1, :"tlsv1.1", :"tlsv1.2"],
  retries: 1,
  # can be `true`
  no_mx_lookups: false,
  # can be `:always`. If your smtp relay requires authentication set it to `:always`.
  auth: :if_available
```

!!! tip
    The hostname option sets the FQDN to the header of your emails, its optional, but if you don't set it, the underlying `gen_smtp` module will use the hostname of your machine, like `localhost`.

You'll need to restart Mobilizon to recompile the app and apply the new settings.