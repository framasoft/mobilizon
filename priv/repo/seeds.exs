# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Eventos.Repo.insert!(%Eventos.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Eventos.Repo.delete_all Eventos.Accounts.User

Eventos.Accounts.User.changeset(%Eventos.Accounts.User{}, %{username: "Test User", email: "testuser@example.com", password: "secret", password_confirmation: "secret"})
|> Eventos.Repo.insert!

