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


{:ok, {privkey, pubkey}} = RsaEx.generate_keypair("4096")
account = Ecto.Changeset.change(%Eventos.Accounts.Account{}, %{
  username: "tcit",
  description: "myaccount",
  display_name: "Thomas Citharel",
  domain: nil,
  private_key: privkey,
  public_key: pubkey,
  uri: "",
  url: ""
})

user = Eventos.Accounts.User.registration_changeset(%Eventos.Accounts.User{}, %{
  email: "tcit@tcit.fr",
  password: "tcittcit",
  password_confirmation: "tcittcit"
})

account_with_user = Ecto.Changeset.put_assoc(account, :user, user)

Eventos.Repo.insert!(account_with_user)
