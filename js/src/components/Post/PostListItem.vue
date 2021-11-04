<template>
  <router-link
    class="post-minimalist-card-wrapper"
    :to="{ name: RouteName.POST, params: { slug: post.slug } }"
  >
    <lazy-image-wrapper
      :picture="post.picture"
      :rounded="true"
      style="height: 120px"
    />
    <div class="title-info-wrapper has-text-grey-dark">
      <p class="post-minimalist-title">{{ post.title }}</p>
      <p class="post-publication-date">
        <b-icon icon="clock" />
        <span class="has-text-grey-dark" v-if="isBeforeLastWeek">{{
          publishedAt | formatDateTimeString(undefined, false, "short")
        }}</span>
        <span v-else>{{
          formatDistanceToNow(publishedAt, {
            locale: $dateFnsLocale,
            addSuffix: true,
          })
        }}</span>
      </p>
      <b-taglist v-if="post.tags.length > 0" style="display: inline">
        <b-icon icon="tag" />
        <b-tag v-for="tag in post.tags" :key="tag.slug">{{ tag.title }}</b-tag>
      </b-taglist>
      <p class="post-publisher has-text-grey-dark" v-if="isCurrentActorMember">
        <b-icon icon="account-edit" />
        <i18n path="Published by {name}">
          <b class="has-text-weight-medium" slot="name">{{
            displayName(post.author)
          }}</b>
        </i18n>
      </p>
    </div>
  </router-link>
</template>
<script lang="ts">
import { formatDistanceToNow, subWeeks, isBefore } from "date-fns";
import { Component, Prop, Vue } from "vue-property-decorator";
import RouteName from "../../router/name";
import { IPost } from "../../types/post.model";
import LazyImageWrapper from "@/components/Image/LazyImageWrapper.vue";
import { displayName } from "@/types/actor";

@Component({
  components: {
    LazyImageWrapper,
  },
})
export default class PostListItem extends Vue {
  @Prop({ required: true, type: Object }) post!: IPost;
  @Prop({ required: false, type: Boolean, default: false })
  isCurrentActorMember!: boolean;

  RouteName = RouteName;

  formatDistanceToNow = formatDistanceToNow;

  displayName = displayName;

  get publishedAt(): Date {
    return new Date((this.post.publishAt || this.post.insertedAt) as Date);
  }

  get isBeforeLastWeek(): boolean {
    return isBefore(this.publishedAt, subWeeks(new Date(), 1));
  }
}
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
@import "~bulma/sass/utilities/mixins.sass";

.post-minimalist-card-wrapper {
  display: grid;
  grid-gap: 5px 10px;
  grid-template-areas: "preview" "body";
  text-decoration: none;
  width: 100%;
  color: initial;

  @include desktop {
    grid-template-columns: 200px 3fr;
    grid-template-areas: "preview body";
  }

  .title-info-wrapper {
    .post-minimalist-title {
      color: #3c376e;
      font-size: 18px;
      line-height: 24px;
      font-weight: 700;
      overflow: hidden;
      display: -webkit-box;
      -webkit-box-orient: vertical;
      -webkit-line-clamp: 3;
    }
  }
  ::v-deep .icon {
    vertical-align: middle;
    @include margin-right(5px);
  }

  ::v-deep .tags {
    display: inline;

    span.tag {
      max-width: 200px;

      & > span {
        overflow: hidden;
        text-overflow: ellipsis;
      }
    }
  }
}
</style>
