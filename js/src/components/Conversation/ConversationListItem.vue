<template>
  <router-link
    class="conversation-minimalist-card-wrapper"
    :to="{ name: RouteName.CONVERSATION, params: { slug: conversation.slug, id: conversation.id } }"
  >
    <div class="media-left">
      <figure class="image is-32x32" v-if="conversation.lastComment.actor.avatar">
        <img class="is-rounded" :src="conversation.lastComment.actor.avatar.url" alt />
      </figure>
      <b-icon v-else size="is-medium" icon="account-circle" />
    </div>
    <div class="title-info-wrapper">
      <p class="conversation-minimalist-title">{{ conversation.title }}</p>
      <div class="has-text-grey">{{ htmlTextEllipsis }}</div>
    </div>
  </router-link>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IConversation } from "../../types/conversations";
import RouteName from "../../router/name";

@Component
export default class ConversationListItem extends Vue {
  @Prop({ required: true, type: Object }) conversation!: IConversation;

  RouteName = RouteName;

  get htmlTextEllipsis() {
    const element = document.createElement("div");
    element.innerHTML = this.conversation.lastComment.text
      .replace(/<br\s*\/?>/gi, " ")
      .replace(/<p>/gi, " ");
    return element.innerText;
  }
}
</script>
<style lang="scss" scoped>
.conversation-minimalist-card-wrapper {
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

    .conversation-minimalist-title {
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
