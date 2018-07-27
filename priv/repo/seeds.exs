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

import Eventos.Factory

# Insert an user
user = insert(:user)

# Insert an actor account
actor = insert(:actor, user: user)

# Insert a second actor account for the same user
actor2 = insert(:actor, user: user)

# Make actor organize an event
event = insert(:event, organizer_actor: actor)

# Insert a group
group = insert(:actor, type: :Group)

