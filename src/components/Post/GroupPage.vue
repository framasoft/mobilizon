<template>
  <div class="posts-wrapper grid gap-4">
    <group-page-multi
      v-for="post in posts"
      :key="post.id"
      :post="post"
      :isCurrentActorMember="isCurrentActorMember"
    />
  </div>
</template>
<script lang="ts" setup>
import { IPost } from "@/types/post.model";
import GroupPageMulti from "./GroupPageMulti.vue";

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
  grid-template: 1fr;
}
</style>
