<template>
  <router-link
    class="discussion-minimalist-card-wrapper"
    :to="{
      name: RouteName.DISCUSSION,
      params: { slug: discussion.slug, id: discussion.id },
    }"
  >
    <div class="media-left">
      <figure
        class="image is-32x32"
        v-if="
          discussion.lastComment.actor && discussion.lastComment.actor.avatar
        "
      >
        <img
          class="is-rounded"
          :src="discussion.lastComment.actor.avatar.url"
          alt
        />
      </figure>
      <b-icon v-else size="is-medium" icon="account-circle" />
    </div>
    <div class="title-info-wrapper">
      <div class="title-and-date">
        <p class="discussion-minimalist-title">{{ discussion.title }}</p>
        <span
          class="has-text-grey-dark"
          :title="actualDate | formatDateTimeString"
        >
          {{
            formatDistanceToNowStrict(new Date(actualDate), {
              locale: $dateFnsLocale,
            }) || $t("Right now")
          }}</span
        >
      </div>
      <div
        class="ellipsis has-text-grey-dark"
        v-if="!discussion.lastComment.deletedAt"
      >
        {{ htmlTextEllipsis }}
      </div>
      <div v-else class="has-text-grey-dark">
        {{ $t("[This comment has been deleted]") }}
      </div>
    </div>
  </router-link>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { formatDistanceToNowStrict } from "date-fns";
import { IDiscussion } from "../../types/discussions";
import RouteName from "../../router/name";

@Component
export default class DiscussionListItem extends Vue {
  @Prop({ required: true, type: Object }) discussion!: IDiscussion;

  RouteName = RouteName;

  formatDistanceToNowStrict = formatDistanceToNowStrict;

  get htmlTextEllipsis(): string {
    const element = document.createElement("div");
    if (this.discussion.lastComment && this.discussion.lastComment.text) {
      element.innerHTML = this.discussion.lastComment.text
        .replace(/<br\s*\/?>/gi, " ")
        .replace(/<p>/gi, " ");
    }
    return element.innerText;
  }

  get actualDate(): string | Date | undefined {
    if (
      this.discussion.updatedAt === this.discussion.insertedAt &&
      this.discussion.lastComment
    ) {
      return this.discussion.lastComment.publishedAt;
    }
    return this.discussion.updatedAt;
  }
}
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
.discussion-minimalist-card-wrapper {
  text-decoration: none;
  display: flex;
  width: 100%;
  color: initial;
  border-bottom: 1px solid #e9e9e9;
  align-items: center;

  .calendar-icon {
    @include margin-right(1rem);
  }

  .title-info-wrapper {
    flex: 2;

    .title-and-date {
      display: flex;
      align-items: center;

      .discussion-minimalist-title {
        color: #3c376e;
        font-family: Roboto, Helvetica, Arial, serif;
        font-size: 19px;
        font-weight: 600;
        flex: 1;
      }
    }

    div.ellipsis {
      overflow: hidden;
      display: -webkit-box;
      -webkit-box-orient: vertical;
      -webkit-line-clamp: 2;
      font-size: 15px;
    }
  }
}
</style>
