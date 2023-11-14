<template>
  <Story>
    <Variant title="Unlogged">
      <ParticipationButton
        :event="event"
        :current-actor="emptyCurrentActor"
        :participation="undefined"
        :identities="[]"
      />
    </Variant>
    <Variant title="Basic">
      <ParticipationButton
        :event="event"
        :current-actor="currentActor"
        :participation="undefined"
        :identities="identities"
        @join-event="logEvent('Join event', $event)"
        @join-modal="logEvent('Join modal', $event)"
        @confirm-leave="logEvent('Confirm leave', $event)"
      />
    </Variant>
    <Variant title="Basic with confirmation">
      <ParticipationButton
        :event="{ ...event, joinOptions: EventJoinOptions.RESTRICTED }"
        :current-actor="currentActor"
        :participation="undefined"
        :identities="identities"
        @join-event-with-confirmation="
          logEvent('Join Event with confirmation', $event)
        "
        @join-modal="logEvent('Join modal', $event)"
      />
    </Variant>
    <Variant title="Participating">
      <ParticipationButton
        :event="event"
        :current-actor="currentActor"
        :participation="participation"
        :identities="identities"
        @confirm-leave="logEvent('Confirm leave', $event)"
      />
    </Variant>
    <Variant title="Pending approval">
      <ParticipationButton
        :event="event"
        :current-actor="currentActor"
        :participation="{
          ...participation,
          role: ParticipantRole.NOT_APPROVED,
        }"
        :identities="identities"
        @confirm-leave="logEvent('Confirm leave', $event)"
      />
    </Variant>
    <Variant title="Rejected">
      <ParticipationButton
        :event="event"
        :current-actor="currentActor"
        :participation="{
          ...participation,
          role: ParticipantRole.REJECTED,
        }"
        :identities="identities"
        @confirm-leave="logEvent('Confirm leave', $event)"
      />
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import { IPerson } from "@/types/actor";
import { EventJoinOptions, ParticipantRole } from "@/types/enums";
import { IEvent } from "@/types/event.model";
import ParticipationButton from "./ParticipationButton.vue";
import { logEvent } from "histoire/client";
import { IParticipant } from "@/types/participant.model";

const emptyCurrentActor: IPerson = {};

const currentActor: IPerson = {
  id: "1",
  preferredUsername: "tcit",
  name: "Thomas",
  avatar: {
    url: "https://mobilizon.fr/media/3a5f18c058a8193b1febfaf561f94ae8b91f85ac64c01ddf5ad7b251fb43baf5.jpg?name=profil.jpg",
  },
};

const participation: IParticipant = {
  actor: currentActor,
  role: ParticipantRole.PARTICIPANT,
};

const identities: IPerson[] = [
  currentActor,
  {
    id: "2",
    preferredUsername: "another",
    name: "Another",
    avatar: {
      url: "https://mobilizon.fr/media/95ab5ba92287ab4857bb517cadae2a7ab6a553748d1c48cefc27e2b7ab640fea.jpg?name=FB_IMG_16150214351371162.jpg",
    },
  },
];

const event: IEvent = {
  title: "hello",
  url: "https://mobilizon.fr/events/an-uuid",
  options: {
    anonymousParticipation: false,
  },
  joinOptions: EventJoinOptions.FREE,
};
</script>
