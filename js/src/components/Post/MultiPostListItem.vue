<template>
  <div class="posts-wrapper">
    <post-list-item
      v-for="post in posts"
      :key="post.id"
      :post="post"
      :isCurrentActorMember="isCurrentActorMember"
    />
  </div>
</template>
<script lang="ts" setup>
import { IPost } from "@/types/post.model";
import PostListItem from "./PostListItem.vue";

withDefaults(
  defineProps<{
    posts: IPost[];
    isCurrentActorMember?: boolean;
  }>(),
  { isCurrentActorMember: false }
);
</script>
<style lang="scss" scoped>
.posts-wrapper {
  display: grid;
  grid-gap: 20px;
  grid-template: 1fr;
}
</style>
