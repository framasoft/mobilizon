<template>
  <Story title="EventListViewCard">
    <Variant title="default">
      <EventListViewCard :event="baseEvent" />
    </Variant>
    <Variant title="long">
      <EventListViewCard :event="longEvent" />
    </Variant>

    <!-- <Variant title="tentative">
      <EventListViewCard :event="tentativeEvent" />
    </Variant>

    <Variant title="cancelled">
      <EventListViewCard :event="cancelledEvent" />
    </Variant> -->
  </Story>
</template>

<script lang="ts" setup>
import { IActor } from "@/types/actor";
import {
  ActorType,
  CommentModeration,
  EventJoinOptions,
  EventStatus,
  EventVisibility,
} from "@/types/enums";
import { IEvent } from "@/types/event.model";
import { reactive } from "vue";
import EventListViewCard from "./EventListViewCard.vue";

const baseActorAvatar = {
  id: "",
  name: "",
  alt: "",
  metadata: {},
  url: "https://social.tcit.fr/system/accounts/avatars/000/000/001/original/a28c50ce5f2b13fd.jpg",
};

const baseActor: IActor = {
  name: "Thomas Citharel",
  preferredUsername: "tcit",
  avatar: baseActorAvatar,
  domain: null,
  url: "",
  summary: "",
  suspended: false,
  type: ActorType.PERSON,
};

const baseEvent: IEvent = {
  uuid: "",
  title: "A very interesting event",
  description: "Things happen",
  beginsOn: new Date().toISOString(),
  endsOn: new Date().toISOString(),
  physicalAddress: {
    description: "Somewhere",
    street: "",
    locality: "",
    region: "",
    country: "",
    type: "",
    postalCode: "",
  },
  picture: {
    id: "",
    name: "",
    alt: "",
    metadata: {},
    url: "https://mobilizon.fr/media/81d9c76aaf740f84eefb28cf2b9988bdd2495ab1f3246159fd688e242155cb23.png?name=Screenshot_20220315_171848.png",
  },
  url: "",
  local: true,
  slug: "",
  publishAt: new Date().toISOString(),
  status: EventStatus.CONFIRMED,
  visibility: EventVisibility.PUBLIC,
  joinOptions: EventJoinOptions.FREE,
  draft: false,
  participantStats: {
    notApproved: 0,
    notConfirmed: 0,
    rejected: 0,
    participant: 0,
    creator: 0,
    moderator: 0,
    administrator: 0,
    going: 0,
  },
  participants: { total: 0, elements: [] },
  relatedEvents: [],
  tags: [{ slug: "something", title: "Something" }],
  attributedTo: undefined,
  organizerActor: {
    ...baseActor,
    name: "Hello",
    avatar: {
      ...baseActorAvatar,
      url: "https://mobilizon.fr/media/653c2dcbb830636e0db975798163b85e038dfb7713e866e96d36bd411e105e3c.png?name=festivalsanantes%27s%20avatar.png",
    },
  },
  comments: [],
  options: {
    maximumAttendeeCapacity: 0,
    remainingAttendeeCapacity: 0,
    showRemainingAttendeeCapacity: false,
    anonymousParticipation: false,
    hideOrganizerWhenGroupEvent: false,
    offers: [],
    participationConditions: [],
    attendees: [],
    program: "",
    commentModeration: CommentModeration.ALLOW_ALL,
    showParticipationPrice: false,
    showStartTime: false,
    showEndTime: false,
    timezone: null,
    isOnline: false,
  },
  metadata: [],
  contacts: [],
  language: "en",
  category: "hello",
};

const longEvent = reactive<IEvent>({
  ...baseEvent,
  title:
    "A very long title that will have trouble to display because it will take multiple lines but where will it stop ?! Maybe after 3 lines is enough. Let's say so.",
});

// const tentativeEvent = reactive<IEvent>({
//   ...baseEvent,
//   status: EventStatus.TENTATIVE,
// });

// const cancelledEvent = reactive<IEvent>({
//   ...baseEvent,
//   status: EventStatus.CANCELLED,
// });
</script>
