<template>
  <Story :setup-app="setupApp">
    <Variant title="Basic">
      <Comment
        :comment="comment"
        :event="event"
        :currentActor="baseActor"
        @create-comment="logEvent('Create comment', $event)"
        @delete-comment="logEvent('Delete comment', $event)"
        @report-comment="logEvent('Report comment', $event)"
      />
    </Variant>
    <Variant title="Announcement">
      <Comment
        :comment="{ ...comment, isAnnouncement: true }"
        :event="event"
        :currentActor="baseActor"
        @create-comment="logEvent('Create comment', $event)"
        @delete-comment="logEvent('Delete comment', $event)"
        @report-comment="logEvent('Report comment', $event)"
      />
    </Variant>
  </Story>
</template>
<script lang="ts" setup>
import { IPerson } from "@/types/actor";
import { IComment } from "@/types/comment.model";
import {
  ActorType,
  CommentModeration,
  EventJoinOptions,
  EventStatus,
  EventVisibility,
} from "@/types/enums";
import { IEvent } from "@/types/event.model";
import { reactive } from "vue";
import Comment from "./EventComment.vue";
import FloatingVue from "floating-vue";
import "floating-vue/dist/style.css";
import { logEvent } from "histoire/client";
import { createMemoryHistory, createRouter } from "vue-router";

function setupApp({ app }) {
  app.use(FloatingVue);
  app.use(
    createRouter({
      history: createMemoryHistory(),
      routes: [
        {
          path: "/event/:uuid",
          name: "Event",
          component: { render: () => null },
        },
      ],
    })
  );
}

const baseActorAvatar = {
  id: "",
  name: "",
  alt: "",
  metadata: {},
  url: "https://social.tcit.fr/system/accounts/avatars/000/000/001/original/a28c50ce5f2b13fd.jpg",
};

const baseActor: IPerson = {
  name: "Thomas Citharel",
  preferredUsername: "tcit",
  avatar: baseActorAvatar,
  domain: null,
  url: "",
  summary: "",
  suspended: false,
  type: ActorType.PERSON,
  id: "598",
};

const baseEvent: IEvent = {
  uuid: "an-uuid",
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

const event = reactive<IEvent>(baseEvent);

const comment = reactive<IComment>({
  text: "hello",
  local: true,
  actor: baseActor,
  totalReplies: 5,
  replies: [
    {
      text: "a reply!",
      id: "90",
      actor: baseActor,
      updatedAt: new Date().toISOString(),
      url: "http://somewhere.tld",
      replies: [],
      totalReplies: 0,
      isAnnouncement: false,
      local: false,
    },
    {
      text: "a reply to another reply!",
      id: "92",
      actor: baseActor,
      updatedAt: new Date().toISOString(),
      url: "http://somewhere.tld",
      replies: [],
      totalReplies: 0,
      isAnnouncement: false,
      local: false,
    },
  ],
  isAnnouncement: false,
  updatedAt: new Date().toISOString(),
  url: "http://somewhere.tld",
});
</script>
