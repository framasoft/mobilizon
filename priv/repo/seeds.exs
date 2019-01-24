# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Mobilizon.Repo.insert!(%Mobilizon.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Mobilizon.Factory

# Insert an user
user = insert(:user)

# Insert an actor account
actor = insert(:actor, user: user)

# Insert a second actor account for the same user
actor2 = insert(:actor, user: user)

# Make actor organize a few events
event = insert(:event, organizer_actor: actor)
event2 = insert(:event, organizer_actor: actor)
event3 = insert(:event, organizer_actor: actor)
event4 = insert(:event, organizer_actor: actor2)

participant = insert(:participant, actor: actor, event: event, role: 4)
participant = insert(:participant, actor: actor, event: event2, role: 4)
participant = insert(:participant, actor: actor, event: event3, role: 4)
participant = insert(:participant, actor: actor2, event: event4, role: 4)
participant = insert(:participant, actor: actor, event: event4, role: 1)

# Insert a group
group = insert(:actor, type: :Group)

