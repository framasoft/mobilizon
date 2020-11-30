<template>
  <router-link
    class="post-minimalist-card-wrapper"
    :to="{ name: RouteName.POST, params: { slug: post.slug } }"
  >
    <div class="title-info-wrapper">
      <p class="post-minimalist-title">{{ post.title }}</p>
      <small class="has-text-grey">{{
        formatDistanceToNow(new Date(post.publishAt || post.insertedAt), {
          locale: $dateFnsLocale,
          addSuffix: true,
        })
      }}</small>
    </div>
  </router-link>
</template>
<script lang="ts">
import { formatDistanceToNow } from "date-fns";
import { Component, Prop, Vue } from "vue-property-decorator";
import RouteName from "../../router/name";
import { IPost } from "../../types/post.model";

@Component
export default class PostListItem extends Vue {
  @Prop({ required: true, type: Object }) post!: IPost;

  RouteName = RouteName;

  formatDistanceToNow = formatDistanceToNow;
}
</script>
<style lang="scss" scoped>
.post-minimalist-card-wrapper {
  text-decoration: none;
  display: flex;
  width: 100%;
  color: initial;
  border-bottom: 1px solid #e9e9e9;
  align-items: center;

  .title-info-wrapper {
    flex: 2;

    .post-minimalist-title {
      color: #3c376e;
      font-family: "Liberation Sans", "Helvetica Neue", Roboto, Helvetica, Arial,
        serif;
      font-size: 1rem;
      font-weight: 700;
      overflow: hidden;
      display: -webkit-box;
      -webkit-box-orient: vertical;
      -webkit-line-clamp: 2;
    }
  }
}
</style>
