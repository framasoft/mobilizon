# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Mobilizon.Storage.Repo.insert!(%Mobilizon.SomeSchema{})
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

tag1 = insert(:tag)
tag2 = insert(:tag)
tag3 = insert(:tag)

# Make actor organize a few events
event = insert(:event, organizer_actor: actor, tags: [tag1, tag2])
event2 = insert(:event, organizer_actor: actor, tags: [tag1, tag2])
event3 = insert(:event, organizer_actor: actor, tags: [tag1])
event4 = insert(:event, organizer_actor: actor2, tags: [tag3, tag2])

insert(:participant, actor: actor, event: event, role: :creator)
insert(:participant, actor: actor, event: event2, role: :creator)
insert(:participant, actor: actor, event: event3, role: :creator)
insert(:participant, actor: actor2, event: event4, role: :creator)
insert(:participant, actor: actor, event: event4, role: :participant)

# Insert a group
group = insert(:actor, type: :Group)
