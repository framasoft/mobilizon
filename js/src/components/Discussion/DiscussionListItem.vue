<template>
  <router-link
    class="discussion-minimalist-card-wrapper"
    :to="{ name: RouteName.DISCUSSION, params: { slug: discussion.slug, id: discussion.id } }"
  >
    <div class="media-left">
      <figure class="image is-32x32" v-if="discussion.lastComment.actor.avatar">
        <img class="is-rounded" :src="discussion.lastComment.actor.avatar.url" alt />
      </figure>
      <b-icon v-else size="is-medium" icon="account-circle" />
    </div>
    <div class="title-info-wrapper">
      <p class="discussion-minimalist-title">{{ discussion.title }}</p>
      <div class="has-text-grey">{{ htmlTextEllipsis }}</div>
    </div>
  </router-link>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IDiscussion } from "../../types/discussions";
import RouteName from "../../router/name";

@Component
export default class DiscussionListItem extends Vue {
  @Prop({ required: true, type: Object }) discussion!: IDiscussion;

  RouteName = RouteName;

  get htmlTextEllipsis() {
    const element = document.createElement("div");
    if (this.discussion.lastComment) {
      element.innerHTML = this.discussion.lastComment.text
        .replace(/<br\s*\/?>/gi, " ")
        .replace(/<p>/gi, " ");
    }
    return element.innerText;
  }
}
</script>
<style lang="scss" scoped>
.discussion-minimalist-card-wrapper {
  text-decoration: none;
  display: flex;
  width: 100%;
  color: initial;
  border-bottom: 1px solid #e9e9e9;
  align-items: center;

  .calendar-icon {
    margin-right: 1rem;
  }

  .title-info-wrapper {
    flex: 2;

    .discussion-minimalist-title {
      color: #3c376e;
      font-family: "Liberation Sans", "Helvetica Neue", Roboto, Helvetica, Arial, serif;
      font-size: 1.25rem;
      font-weight: 700;
    }

    div.has-text-grey {
      overflow: hidden;
      display: -webkit-box;
      -webkit-box-orient: vertical;
      -webkit-line-clamp: 2;
    }
  }
}
</style>
