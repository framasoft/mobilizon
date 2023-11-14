<template>
  <Story>
    <Variant title="Basic">
      <DiscussionListItem :discussion="discussion" />
    </Variant>
    <Variant title="Deleted comment">
      <DiscussionListItem :discussion="discussionWithDeletedComment" />
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import { IDiscussion } from "@/types/discussions";
import { reactive } from "vue";
import DiscussionListItem from "./DiscussionListItem.vue";

const discussion = reactive<IDiscussion>({
  title: "A discussion",
  comments: { total: 5, elements: [] },
  insertedAt: new Date().toString(),
  updatedAt: new Date().toString(),
  deletedAt: null,
  lastComment: { text: "Hello there", publishedAt: new Date().toString() },
});

const discussionWithDeletedComment = reactive<IDiscussion>({
  ...discussion,
  lastComment: {
    ...discussion.lastComment,
    deletedAt: new Date().toString(),
  },
});
</script>
