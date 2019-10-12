defmodule EndToEndSeed do
  alias Mobilizon.Users

  def delete_user(email) do
    with {:ok, user} <- Users.get_user_by_email(email) do
      Users.delete_user(user)
    end
  end
end

alias Mobilizon.Users
alias Mobilizon.Users.User
alias Mobilizon.Actors
alias Mobilizon.Actors.Actor

if Application.get_env(:mobilizon, :env) != :e2e do
  exit(:shutdown)
end

# An user that has just been registered
test_user_unconfirmed = %{email: "unconfirmed@email.com", password: "some password"}

# An user that has registered and has confirmed their account, but no attached identity
test_user_confirmed = %{email: "confirmed@email.com", password: "some password"}

# An user that has registered and has confirmed their account, with a profile
test_user = %{email: "user@email.com", password: "some password"}
test_actor = %{preferred_username: "test_user", name: "I'm a test user", domain: nil}

EndToEndSeed.delete_user(test_user_unconfirmed.email)
EndToEndSeed.delete_user(test_user_confirmed.email)
EndToEndSeed.delete_user(test_user.email)

{:ok, %User{} = _user_unconfirmed} = Users.register(test_user_unconfirmed)

{:ok, %User{} = user_confirmed} = Users.register(test_user_confirmed)

Users.update_user(user_confirmed, %{
  "confirmed_at" => Timex.shift(user_confirmed.confirmation_sent_at, hours: -3),
  "confirmation_sent_at" => nil,
  "confirmation_token" => nil
})

{:ok, %User{} = user} = Users.register(test_user)

Users.update_user(user, %{
  "confirmed_at" => Timex.shift(user.confirmation_sent_at, hours: -3),
  "confirmation_sent_at" => nil,
  "confirmation_token" => nil
})

{:ok, %Actor{}} =
  Actors.new_person(%{
    user_id: user.id,
    preferred_username: test_actor.preferred_username,
    name: test_actor.name
  })
