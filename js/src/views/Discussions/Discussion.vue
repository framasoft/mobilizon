<template>
  <div class="container section" v-if="discussion">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.MY_GROUPS }">{{
            $t("My groups")
          }}</router-link>
        </li>
        <li>
          <router-link
            v-if="discussion.actor"
            :to="{
              name: RouteName.GROUP,
              params: {
                preferredUsername: usernameWithDomain(discussion.actor),
              },
            }"
            >{{ discussion.actor.name }}</router-link
          >
          <b-skeleton v-else animated />
        </li>
        <li>
          <router-link
            v-if="discussion.actor"
            :to="{
              name: RouteName.DISCUSSION_LIST,
              params: {
                preferredUsername: usernameWithDomain(discussion.actor),
              },
            }"
            >{{ $t("Discussions") }}</router-link
          >
          <b-skeleton animated v-else />
        </li>
        <li class="is-active">
          <router-link
            :to="{ name: RouteName.DISCUSSION, params: { id: discussion.id } }"
            >{{ discussion.title }}</router-link
          >
        </li>
      </ul>
    </nav>
    <section>
      <div class="discussion-title">
        <h2 class="title" v-if="discussion.title && !editTitleMode">
          {{ discussion.title }}
          <span
            v-if="
              currentActor.id === discussion.creator.id ||
              isCurrentActorAGroupModerator
            "
            @click="
              () => {
                newTitle = discussion.title;
                editTitleMode = true;
              }
            "
          >
            <b-icon icon="pencil" />
          </span>
        </h2>
        <b-skeleton v-else-if="!editTitleMode" height="50px" animated />
        <form v-else @submit.prevent="updateDiscussion" class="title-edit">
          <b-input :value="discussion.title" v-model="newTitle" />
          <div class="buttons">
            <b-button
              type="is-primary"
              native-type="submit"
              icon-right="check"
            />
            <b-button
              @click="
                () => {
                  editTitleMode = false;
                  newTitle = '';
                }
              "
              icon-right="close"
            />
            <b-button
              @click="deleteConversation"
              type="is-danger"
              native-type="button"
              icon-left="delete"
              >{{ $t("Delete conversation") }}</b-button
            >
          </div>
        </form>
      </div>
      <discussion-comment
        v-for="comment in discussion.comments.elements"
        :key="comment.id"
        :comment="comment"
        @update-comment="updateComment"
        @delete-comment="deleteComment"
      />
      <b-button
        v-if="discussion.comments.elements.length < discussion.comments.total"
        @click="loadMoreComments"
        >{{ $t("Fetch more") }}</b-button
      >
      <form @submit.prevent="reply">
        <b-field :label="$t('Text')">
          <editor v-model="newComment" />
        </b-field>
        <b-button
          native-type="submit"
          :disabled="['<p></p>', ''].includes(newComment)"
          type="is-primary"
          >{{ $t("Reply") }}</b-button
        >
      </form>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Prop } from "vue-property-decorator";
import { mixins } from "vue-class-component";
import {
  GET_DISCUSSION,
  REPLY_TO_DISCUSSION,
  UPDATE_DISCUSSION,
  DELETE_DISCUSSION,
  DISCUSSION_COMMENT_CHANGED,
} from "@/graphql/discussion";
import { IDiscussion, Discussion } from "@/types/discussions";
import { usernameWithDomain } from "@/types/actor";
import DiscussionComment from "@/components/Discussion/DiscussionComment.vue";
import { GraphQLError } from "graphql";
import { DELETE_COMMENT, UPDATE_COMMENT } from "@/graphql/comment";
import GroupMixin from "@/mixins/group";
import RouteName from "../../router/name";
import { IComment } from "../../types/comment.model";

@Component({
  apollo: {
    discussion: {
      query: GET_DISCUSSION,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          slug: this.slug,
          page: 1,
          limit: this.COMMENTS_PER_PAGE,
        };
      },
      skip() {
        return !this.slug;
      },
      error({ graphQLErrors }) {
        this.handleErrors(graphQLErrors);
      },
      update: (data) => new Discussion(data.discussion),
      subscribeToMore: {
        document: DISCUSSION_COMMENT_CHANGED,
        variables() {
          return {
            slug: this.slug,
          };
        },
        updateQuery: (previousResult, { subscriptionData }) => {
          const previousDiscussion = previousResult.discussion;
          console.log("updating subscription with ", subscriptionData);
          if (
            !previousDiscussion.comments.elements.find(
              (comment: IComment) =>
                comment.id ===
                subscriptionData.data.discussionCommentChanged.lastComment.id
            )
          ) {
            previousDiscussion.lastComment =
              subscriptionData.data.discussionCommentChanged.lastComment;
            previousDiscussion.comments.elements.push(
              subscriptionData.data.discussionCommentChanged.lastComment
            );
            previousDiscussion.comments.total += 1;
          }

          return previousDiscussion;
        },
      },
    },
  },
  components: {
    DiscussionComment,
    editor: () =>
      import(/* webpackChunkName: "editor" */ "@/components/Editor.vue"),
  },
  metaInfo() {
    return {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: this.discussion.title,
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class discussion extends mixins(GroupMixin) {
  @Prop({ type: String, required: true }) slug!: string;

  discussion: IDiscussion = new Discussion();

  newComment = "";

  newTitle = "";

  editTitleMode = false;

  page = 1;

  hasMoreComments = true;

  COMMENTS_PER_PAGE = 10;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  async reply(): Promise<void> {
    if (this.newComment === "") return;

    await this.$apollo.mutate({
      mutation: REPLY_TO_DISCUSSION,
      variables: {
        discussionId: this.discussion.id,
        text: this.newComment,
      },
      update: (store, { data: { replyToDiscussion } }) => {
        const discussionData = store.readQuery<{
          discussion: IDiscussion;
        }>({
          query: GET_DISCUSSION,
          variables: {
            slug: this.slug,
            page: this.page,
          },
        });
        if (!discussionData) return;
        const { discussion: discussionCached } = discussionData;
        discussionCached.lastComment = replyToDiscussion.lastComment;
        discussionCached.comments.elements.push(replyToDiscussion.lastComment);
        discussionCached.comments.total += 1;
        store.writeQuery({
          query: GET_DISCUSSION,
          variables: { slug: this.slug, page: this.page },
          data: { discussion: discussionCached },
        });
      },
      // We don't need to handle cache update since
      // there's the subscription that handles this for us
    });
    this.newComment = "";
  }

  async updateComment(comment: IComment): Promise<void> {
    await this.$apollo.mutate<{ deleteComment: IComment }>({
      mutation: UPDATE_COMMENT,
      variables: {
        commentId: comment.id,
        text: comment.text,
      },
      update: (store, { data }) => {
        if (!data || !data.deleteComment) return;
        const discussionData = store.readQuery<{
          discussion: IDiscussion;
        }>({
          query: GET_DISCUSSION,
          variables: {
            slug: this.slug,
            page: this.page,
          },
        });
        if (!discussionData) return;
        const { discussion: discussionCached } = discussionData;
        const index = discussionCached.comments.elements.findIndex(
          ({ id }) => id === data.deleteComment.id
        );
        if (index > -1) {
          discussionCached.comments.elements.splice(index, 1);
          discussionCached.comments.total -= 1;
        }
        store.writeQuery({
          query: GET_DISCUSSION,
          variables: { slug: this.slug, page: this.page },
          data: { discussion: discussionCached },
        });
      },
    });
  }

  async deleteComment(comment: IComment): Promise<void> {
    await this.$apollo.mutate<{ deleteComment: IComment }>({
      mutation: DELETE_COMMENT,
      variables: {
        commentId: comment.id,
      },
      update: (store, { data }) => {
        if (!data || !data.deleteComment) return;
        const discussionData = store.readQuery<{
          discussion: IDiscussion;
        }>({
          query: GET_DISCUSSION,
          variables: {
            slug: this.slug,
            page: this.page,
          },
        });
        if (!discussionData) return;
        const { discussion: discussionCached } = discussionData;
        const index = discussionCached.comments.elements.findIndex(
          ({ id }) => id === data.deleteComment.id
        );
        if (index > -1) {
          const updatedComment = discussionCached.comments.elements[index];
          updatedComment.deletedAt = new Date();
          updatedComment.actor = null;
          updatedComment.text = "";
          discussionCached.comments.elements.splice(index, 1, updatedComment);
        }
        store.writeQuery({
          query: GET_DISCUSSION,
          variables: { slug: this.slug, page: this.page },
          data: { discussion: discussionCached },
        });
      },
    });
  }

  async loadMoreComments(): Promise<void> {
    if (!this.hasMoreComments) return;
    this.page += 1;
    try {
      await this.$apollo.queries.discussion.fetchMore({
        // New variables
        variables: {
          slug: this.slug,
          page: this.page,
          limit: this.COMMENTS_PER_PAGE,
        },
        // Transform the previous result with new data
        updateQuery: (previousResult, { fetchMoreResult }) => {
          if (!fetchMoreResult) return previousResult;
          const newComments = fetchMoreResult.discussion.comments.elements;
          this.hasMoreComments = newComments.length === 1;
          const { discussion: discussionCached } = previousResult;
          discussionCached.comments.elements = [
            ...previousResult.discussion.comments.elements,
            ...newComments,
          ];

          return { discussion: discussionCached };
        },
      });
    } catch (e) {
      console.error(e);
    }
  }

  async updateDiscussion(): Promise<void> {
    await this.$apollo.mutate({
      mutation: UPDATE_DISCUSSION,
      variables: {
        discussionId: this.discussion.id,
        title: this.newTitle,
      },
      update: (store, { data: { updateDiscussion } }) => {
        const discussionData = store.readQuery<{
          discussion: IDiscussion;
        }>({
          query: GET_DISCUSSION,
          variables: {
            slug: this.slug,
            page: this.page,
          },
        });
        if (!discussionData) return;
        const { discussion: discussionCached } = discussionData;
        discussionCached.title = updateDiscussion.title;
        store.writeQuery({
          query: GET_DISCUSSION,
          variables: { slug: this.slug, page: this.page },
          data: { discussion: discussionCached },
        });
      },
    });
    this.editTitleMode = false;
  }

  async deleteConversation(): Promise<void> {
    await this.$apollo.mutate({
      mutation: DELETE_DISCUSSION,
      variables: {
        discussionId: this.discussion.id,
      },
    });
    if (this.discussion.actor) {
      this.$router.push({
        name: RouteName.DISCUSSION_LIST,
        params: {
          preferredUsername: usernameWithDomain(this.discussion.actor),
        },
      });
    }
  }

  async handleErrors(errors: GraphQLError[]): Promise<void> {
    if (errors[0].message.includes("No such discussion")) {
      await this.$router.push({ name: RouteName.PAGE_NOT_FOUND });
    }
  }

  mounted(): void {
    window.addEventListener("scroll", this.handleScroll);
  }

  destroyed(): void {
    window.removeEventListener("scroll", this.handleScroll);
  }

  handleScroll(): void {
    const scrollTop =
      (document.documentElement && document.documentElement.scrollTop) ||
      document.body.scrollTop;
    const scrollHeight =
      (document.documentElement && document.documentElement.scrollHeight) ||
      document.body.scrollHeight;
    const clientHeight =
      document.documentElement.clientHeight || window.innerHeight;
    const scrolledToBottom =
      Math.ceil(scrollTop + clientHeight + 800) >= scrollHeight;
    if (scrolledToBottom) {
      this.loadMoreComments();
    }
  }
}
</script>
<style lang="scss" scoped>
div.container.section {
  background: white;
  padding: 1rem 5% 4rem;

  div.discussion-title {
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
