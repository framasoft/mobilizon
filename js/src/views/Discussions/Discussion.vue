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
          <b-skeleton v-else-if="$apollo.loading" animated />
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
          <b-skeleton animated v-else-if="$apollo.loading" />
        </li>
        <li class="is-active">
          <router-link
            :to="{ name: RouteName.DISCUSSION, params: { id: discussion.id } }"
            >{{ discussion.title }}</router-link
          >
        </li>
      </ul>
    </nav>
    <b-message v-if="error" type="is-danger">
      {{ error }}
    </b-message>
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
        <b-skeleton
          v-else-if="!editTitleMode && $apollo.loading"
          height="50px"
          animated
        />
        <form
          v-else-if="!$apollo.loading && !error"
          @submit.prevent="updateDiscussion"
          class="title-edit"
        >
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
              @click="openDeleteDiscussionConfirmation"
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
      <form @submit.prevent="reply" v-if="!error">
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
import {
  GET_DISCUSSION,
  REPLY_TO_DISCUSSION,
  UPDATE_DISCUSSION,
  DELETE_DISCUSSION,
  DISCUSSION_COMMENT_CHANGED,
} from "@/graphql/discussion";
import { IDiscussion } from "@/types/discussions";
import { Discussion as DiscussionModel } from "@/types/discussions";
import { usernameWithDomain } from "@/types/actor";
import DiscussionComment from "@/components/Discussion/DiscussionComment.vue";
import { GraphQLError } from "graphql";
import { DELETE_COMMENT, UPDATE_COMMENT } from "@/graphql/comment";
import RouteName from "../../router/name";
import { IComment } from "../../types/comment.model";
import { ApolloCache, FetchResult } from "@apollo/client/core";
import { mixins } from "vue-class-component";
import GroupMixin from "@/mixins/group";

@Component({
  apollo: {
    discussion: {
      query: GET_DISCUSSION,
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
      subscribeToMore: {
        document: DISCUSSION_COMMENT_CHANGED,
        variables() {
          return {
            slug: this.$route.params.slug,
            page: this.page,
            limit: this.COMMENTS_PER_PAGE,
          };
        },
        updateQuery: function (
          previousResult: any,
          { subscriptionData }: { subscriptionData: any }
        ) {
          const previousDiscussion = previousResult.discussion;
          const lastComment =
            subscriptionData.data.discussionCommentChanged.lastComment;
          this.hasMoreComments = !previousDiscussion.comments.elements.some(
            (comment: IComment) => comment.id === lastComment.id
          );
          if (this.hasMoreComments) {
            return {
              discussion: {
                ...previousDiscussion,
                lastComment: lastComment,
                comments: {
                  elements: [
                    ...previousDiscussion.comments.elements.filter(
                      ({ id }: { id: string }) => id !== lastComment.id
                    ),
                    lastComment,
                  ],
                  total: previousDiscussion.comments.total + 1,
                },
              },
            };
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
    };
  },
})
export default class Discussion extends mixins(GroupMixin) {
  @Prop({ type: String, required: true }) slug!: string;

  discussion: IDiscussion = new DiscussionModel();

  newComment = "";

  newTitle = "";

  editTitleMode = false;

  page = 1;

  hasMoreComments = true;

  COMMENTS_PER_PAGE = 10;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;
  error: string | null = null;

  async reply(): Promise<void> {
    if (this.newComment === "") return;

    await this.$apollo.mutate({
      mutation: REPLY_TO_DISCUSSION,
      variables: {
        discussionId: this.discussion.id,
        text: this.newComment,
      },
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
      update: (
        store: ApolloCache<{ deleteComment: IComment }>,
        { data }: FetchResult
      ) => {
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
      update: (
        store: ApolloCache<{ deleteComment: IComment }>,
        { data }: FetchResult
      ) => {
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
        let discussionUpdated = discussionCached;
        if (index > -1) {
          const updatedComment = {
            ...discussionCached.comments.elements[index],
            deletedAt: new Date(),
            actor: null,
            updatedComment: {
              text: "",
            },
          };
          const elements = [...discussionCached.comments.elements];
          elements.splice(index, 1, updatedComment);
          discussionUpdated = {
            ...discussionCached,
            comments: {
              total: discussionCached.comments.total,
              elements,
            },
          };
        }
        store.writeQuery({
          query: GET_DISCUSSION,
          variables: { slug: this.slug, page: this.page },
          data: { discussion: discussionUpdated },
        });
      },
    });
  }

  async loadMoreComments(): Promise<void> {
    if (!this.hasMoreComments) return;
    this.page++;
    try {
      await this.$apollo.queries.discussion.fetchMore({
        // New variables
        variables: {
          slug: this.slug,
          page: this.page,
          limit: this.COMMENTS_PER_PAGE,
        },
        updateQuery: (previousResult, { fetchMoreResult }) => {
          return {
            discussion: {
              ...previousResult.discussion,
              comments: {
                ...fetchMoreResult.discussion.comments,
                elements: [
                  ...previousResult.discussion.comments.elements,
                  ...fetchMoreResult.discussion.comments.elements,
                ],
              },
            },
          };
        },
      });
      this.hasMoreComments = !this.discussion.comments.elements
        .map(({ id }) => id)
        .includes(this.discussion?.lastComment?.id);
    } catch (e) {
      console.error(e);
    }
  }

  async updateDiscussion(): Promise<void> {
    await this.$apollo.mutate<{ updateDiscussion: IDiscussion }>({
      mutation: UPDATE_DISCUSSION,
      variables: {
        discussionId: this.discussion.id,
        title: this.newTitle,
      },
      update: (
        store: ApolloCache<{ updateDiscussion: IDiscussion }>,
        { data }: FetchResult<{ updateDiscussion: IDiscussion }>
      ) => {
        const discussionData = store.readQuery<{
          discussion: IDiscussion;
        }>({
          query: GET_DISCUSSION,
          variables: {
            slug: this.slug,
            page: this.page,
          },
        });
        if (discussionData && data?.updateDiscussion) {
          store.writeQuery({
            query: GET_DISCUSSION,
            variables: { slug: this.slug, page: this.page },
            data: {
              discussion: {
                ...discussionData.discussion,
                title: data?.updateDiscussion.title,
              },
            },
          });
        }
      },
    });
    this.editTitleMode = false;
  }

  openDeleteDiscussionConfirmation(): void {
    this.$buefy.dialog.confirm({
      type: "is-danger",
      title: this.$t("Delete this discussion") as string,
      message: this.$t(
        "Are you sure you want to delete this entire discussion?"
      ) as string,
      confirmText: this.$t("Delete discussion") as string,
      cancelText: this.$t("Cancel") as string,
      onConfirm: () => this.deleteConversation(),
    });
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
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    if (errors[0].code === "unauthorized") {
      this.error = errors[0].message;
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
