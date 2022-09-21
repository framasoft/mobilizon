<template>
  <Story>
    <Variant title="Basic">
      <DiscussionComment v-model="comment" :currentActor="baseActor" />
    </Variant>
    <Variant title="Deleted comment">
      <DiscussionComment v-model="deletedComment" :currentActor="baseActor" />
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import { IPerson } from "@/types/actor";
import { IComment } from "@/types/comment.model";
import { ActorType } from "@/types/enums";
import { reactive } from "vue";
import DiscussionComment from "./DiscussionComment.vue";

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

const comment = reactive<IComment>({
  text: "Hello there",
  publishedAt: new Date().toString(),
  actor: baseActor,
});

const deletedComment = reactive<IComment>({
  ...comment,
  actor: null,
  deletedAt: new Date().toString(),
});
</script>
