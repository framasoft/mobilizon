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
<script lang="ts">
import { IPost } from "@/types/post.model";
import { PropType } from "vue";
import { Component, Prop, Vue } from "vue-property-decorator";
import PostListItem from "./PostListItem.vue";

@Component({
  components: {
    PostListItem,
  },
})
export default class MultiPostListItem extends Vue {
  @Prop({ type: Array as PropType<IPost[]>, required: true }) posts!: IPost[];
  @Prop({ required: false, type: Boolean, default: false })
  isCurrentActorMember!: boolean;
}
</script>
<style lang="scss" scoped>
.posts-wrapper {
  display: grid;
  grid-gap: 20px;
  grid-template: 1fr;
}
</style>
