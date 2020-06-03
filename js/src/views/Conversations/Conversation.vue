<template>
  <div class="container section" v-if="conversation">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.MY_GROUPS }">{{ $t("My groups") }}</router-link>
        </li>
        <li>
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: { preferredUsername: conversation.actor.preferredUsername },
            }"
            >{{ `@${conversation.actor.preferredUsername}` }}</router-link
          >
        </li>
        <li>
          <router-link
            :to="{
              name: RouteName.CONVERSATION_LIST,
              params: { preferredUsername: conversation.actor.preferredUsername },
            }"
            >{{ $t("Conversations") }}</router-link
          >
        </li>
        <li class="is-active">
          <router-link :to="{ name: RouteName.CONVERSATION, params: { id: conversation.id } }">{{
            conversation.title
          }}</router-link>
        </li>
      </ul>
    </nav>
    <section>
      <div class="conversation-title">
        <h2 class="title" v-if="!editTitleMode">
          {{ conversation.title }}
          <span
            @click="
              () => {
                newTitle = conversation.title;
                editTitleMode = true;
              }
            "
          >
            <b-icon icon="pencil" />
          </span>
        </h2>
        <form v-else @submit.prevent="updateConversation" class="title-edit">
          <b-input :value="conversation.title" v-model="newTitle" />
          <div class="buttons">
            <b-button type="is-primary" native-type="submit" icon-right="check" />
            <b-button
              @click="
                () => {
                  editTitleMode = false;
                  newTitle = '';
                }
              "
              icon-right="close"
            />
          </div>
        </form>
      </div>
      <conversation-comment
        v-for="comment in conversation.comments.elements"
        :key="comment.id"
        :comment="comment"
      />
      <b-button
        v-if="conversation.comments.elements.length < conversation.comments.total"
        @click="loadMoreComments"
        >Fetch more</b-button
      >
      <form @submit.prevent="reply">
        <b-field :label="$t('Text')">
          <editor v-model="newComment" />
        </b-field>
        <b-button native-type="submit" type="is-primary">{{ $t("Reply") }}</b-button>
      </form>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import {
  GET_CONVERSATION,
  REPLY_TO_CONVERSATION,
  UPDATE_CONVERSATION,
} from "@/graphql/conversation";
import { IConversation } from "@/types/conversations";
import ConversationComment from "@/components/Conversation/ConversationComment.vue";
import RouteName from "../../router/name";

@Component({
  apollo: {
    conversation: {
      query: GET_CONVERSATION,
      variables() {
        return {
          id: this.id,
          page: 1,
        };
      },
      skip() {
        return !this.id;
      },
    },
  },
  components: {
    ConversationComment,
    editor: () => import(/* webpackChunkName: "editor" */ "@/components/Editor.vue"),
  },
})
export default class Conversation extends Vue {
  @Prop({ type: String, required: true }) id!: string;

  conversation!: IConversation;

  newComment = "";

  newTitle = "";

  editTitleMode = false;

  page = 1;

  hasMoreComments = true;

  RouteName = RouteName;

  async reply() {
    await this.$apollo.mutate({
      mutation: REPLY_TO_CONVERSATION,
      variables: {
        conversationId: this.conversation.id,
        text: this.newComment,
      },
      update: (store, { data: { replyToConversation } }) => {
        const conversationData = store.readQuery<{
          conversation: IConversation;
        }>({
          query: GET_CONVERSATION,
          variables: {
            id: this.id,
            page: this.page,
          },
        });
        if (!conversationData) return;
        const { conversation } = conversationData;
        conversation.lastComment = replyToConversation.lastComment;
        conversation.comments.elements.push(replyToConversation.lastComment);
        conversation.comments.total += 1;
        store.writeQuery({
          query: GET_CONVERSATION,
          variables: { id: this.id, page: this.page },
          data: { conversation },
        });
      },
    });
    this.newComment = "";
  }

  async loadMoreComments() {
    this.page += 1;
    try {
      console.log(this.$apollo.queries.conversation);
      await this.$apollo.queries.conversation.fetchMore({
        // New variables
        variables: {
          id: this.id,
          page: this.page,
        },
        // Transform the previous result with new data
        updateQuery: (previousResult, { fetchMoreResult }) => {
          if (!fetchMoreResult) return previousResult;
          const newComments = fetchMoreResult.conversation.comments.elements;
          this.hasMoreComments = newComments.length === 1;
          const { conversation } = previousResult;
          conversation.comments.elements = [
            ...previousResult.conversation.comments.elements,
            ...newComments,
          ];

          return { conversation };
        },
      });
    } catch (e) {
      console.error(e);
    }
  }

  async updateConversation() {
    await this.$apollo.mutate({
      mutation: UPDATE_CONVERSATION,
      variables: {
        conversationId: this.conversation.id,
        title: this.newTitle,
      },
      update: (store, { data: { updateConversation } }) => {
        const conversationData = store.readQuery<{
          conversation: IConversation;
        }>({
          query: GET_CONVERSATION,
          variables: {
            id: this.id,
            page: this.page,
          },
        });
        if (!conversationData) return;
        const { conversation } = conversationData;
        conversation.title = updateConversation.title;
        store.writeQuery({
          query: GET_CONVERSATION,
          variables: { id: this.id, page: this.page },
          data: { conversation },
        });
      },
    });
    this.editTitleMode = false;
  }
}
</script>
<style lang="scss" scoped>
div.container.section {
  background: white;

  div.conversation-title {
    margin-bottom: 0.75rem;

    h2.title {
      span {
        cursor: pointer;
      }
    }

    form.title-edit {
      div.control {
        margin-bottom: 0.75rem;
      }
    }
  }
}
</style>
