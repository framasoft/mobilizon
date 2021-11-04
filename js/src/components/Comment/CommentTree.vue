<template>
  <div>
    <form
      class="new-comment"
      v-if="isAbleToComment"
      @submit.prevent="createCommentForEvent(newComment)"
      @keyup.ctrl.enter="createCommentForEvent(newComment)"
    >
      <b-notification
        v-if="isEventOrganiser && !areCommentsClosed"
        :closable="false"
        >{{ $t("Comments are closed for everybody else.") }}</b-notification
      >
      <article class="media">
        <figure class="media-left" v-if="newComment.actor">
          <identity-picker-wrapper :inline="false" v-model="newComment.actor" />
        </figure>
        <div class="media-content">
          <div class="field">
            <div class="field">
              <p class="control">
                <editor
                  ref="commenteditor"
                  mode="comment"
                  v-model="newComment.text"
                  :aria-label="$t('Comment body')"
                />
              </p>
              <p class="help is-danger" v-if="emptyCommentError">
                {{ $t("Comment text can't be empty") }}
              </p>
            </div>
            <div class="field notify-participants" v-if="isEventOrganiser">
              <b-switch
                aria-labelledby="notify-participants-toggle"
                v-model="newComment.isAnnouncement"
                >{{ $t("Notify participants") }}</b-switch
              >
            </div>
          </div>
        </div>
        <div class="send-comment">
          <b-button
            native-type="submit"
            type="is-primary"
            class="comment-button-submit"
            icon-left="send"
            :aria-label="$t('Post a comment')"
          />
        </div>
      </article>
    </form>
    <b-notification v-else-if="isConnected" :closable="false">{{
      $t("The organiser has chosen to close comments.")
    }}</b-notification>
    <p
      v-if="$apollo.queries.comments.loading"
      class="loading has-text-centered"
    >
      {{ $t("Loading comments…") }}
    </p>
    <transition-group name="comment-empty-list" mode="out-in" v-else>
      <transition-group
        key="list"
        name="comment-list"
        v-if="comments.length"
        class="comment-list"
        tag="ul"
      >
        <comment
          class="root-comment"
          :comment="comment"
          :event="event"
          v-for="comment in filteredOrderedComments"
          :key="comment.id"
          @create-comment="createCommentForEvent"
          @delete-comment="deleteComment"
        />
      </transition-group>
      <div v-else class="no-comments" key="no-comments">
        <span>{{ $t("No comments yet") }}</span>
      </div>
    </transition-group>
  </div>
</template>

<script lang="ts">
import { Prop, Vue, Component, Watch } from "vue-property-decorator";
import Comment from "@/components/Comment/Comment.vue";
import IdentityPickerWrapper from "@/views/Account/IdentityPickerWrapper.vue";
import { CommentModeration } from "@/types/enums";
import { CommentModel, IComment } from "../../types/comment.model";
import {
  CREATE_COMMENT_FROM_EVENT,
  DELETE_COMMENT,
  COMMENTS_THREADS_WITH_REPLIES,
} from "../../graphql/comment";
import { CURRENT_ACTOR_CLIENT } from "../../graphql/actor";
import { IPerson } from "../../types/actor";
import { IEvent } from "../../types/event.model";
import { ApolloCache, FetchResult, InMemoryCache } from "@apollo/client/core";

@Component({
  apollo: {
    currentActor: CURRENT_ACTOR_CLIENT,
    comments: {
      query: COMMENTS_THREADS_WITH_REPLIES,
      variables() {
        return {
          eventUUID: this.event.uuid,
        };
      },
      update: (data) => data.event.comments,
      skip() {
        return !this.event.uuid;
      },
    },
  },
  components: {
    Comment,
    IdentityPickerWrapper,
    editor: () =>
      import(/* webpackChunkName: "editor" */ "@/components/Editor.vue"),
  },
})
export default class CommentTree extends Vue {
  @Prop({ required: false, type: Object }) event!: IEvent;

  newComment: IComment = new CommentModel();

  currentActor!: IPerson;

  comments: IComment[] = [];

  CommentModeration = CommentModeration;

  emptyCommentError = false;

  @Watch("currentActor")
  watchCurrentActor(currentActor: IPerson): void {
    this.newComment.actor = currentActor;
  }

  @Watch("newComment", { deep: true })
  resetEmptyCommentError(newComment: IComment): void {
    if (this.emptyCommentError) {
      this.emptyCommentError = ["", "<p></p>"].includes(newComment.text);
    }
  }

  async createCommentForEvent(comment: IComment): Promise<void> {
    this.emptyCommentError = ["", "<p></p>"].includes(comment.text);
    if (this.emptyCommentError) return;
    try {
      if (!comment.actor) return;
      await this.$apollo.mutate({
        mutation: CREATE_COMMENT_FROM_EVENT,
        variables: {
          eventId: this.event.id,
          text: comment.text,
          inReplyToCommentId: comment.inReplyToComment
            ? comment.inReplyToComment.id
            : null,
          isAnnouncement: comment.isAnnouncement,
        },
        update: (store: ApolloCache<InMemoryCache>, { data }: FetchResult) => {
          if (data == null) return;
          // comments are attached to the event, so we can pass it to replies later
          const newComment = { ...data.createComment, event: this.event };

          // we load all existing threads
          const commentThreadsData = store.readQuery<{ event: IEvent }>({
            query: COMMENTS_THREADS_WITH_REPLIES,
            variables: {
              eventUUID: this.event.uuid,
            },
          });
          if (!commentThreadsData) return;
          const { event } = commentThreadsData;
          const oldComments = [...event.comments];

          // if it's no a root comment, we first need to find
          // existing replies and add the new reply to it
          if (comment.originComment !== undefined) {
            const { originComment } = comment;
            const parentCommentIndex = oldComments.findIndex(
              (oldComment) => oldComment.id === originComment.id
            );
            const parentComment = oldComments[parentCommentIndex];

            // replace the root comment with has the updated list of replies in the thread list
            oldComments.splice(parentCommentIndex, 1, {
              ...parentComment,
              replies: [...parentComment.replies, newComment],
            });
          } else {
            // otherwise it's simply a new thread and we add it to the list
            oldComments.push(newComment);
          }

          // finally we save the thread list
          store.writeQuery({
            query: COMMENTS_THREADS_WITH_REPLIES,
            data: {
              event: {
                ...event,
                comments: oldComments,
              },
            },
            variables: {
              eventUUID: this.event.uuid,
            },
          });
        },
      });

      // and reset the new comment field
      this.newComment = new CommentModel();
    } catch (errors: any) {
      console.error(errors);
      if (errors.graphQLErrors && errors.graphQLErrors.length > 0) {
        const error = errors.graphQLErrors[0];
        if (error.field !== "text" && error.message[0] !== "can't be blank") {
          this.$notifier.error(error.message);
        }
      }
    }
  }

  async deleteComment(comment: IComment): Promise<void> {
    try {
      await this.$apollo.mutate({
        mutation: DELETE_COMMENT,
        variables: {
          commentId: comment.id,
        },
        update: (store: ApolloCache<InMemoryCache>, { data }: FetchResult) => {
          if (data == null) return;
          const deletedCommentId = data.deleteComment.id;

          const commentsData = store.readQuery<{ event: IEvent }>({
            query: COMMENTS_THREADS_WITH_REPLIES,
            variables: {
              eventUUID: this.event.uuid,
            },
          });
          if (!commentsData) return;
          const { event } = commentsData;
          let updatedComments: IComment[] = [...event.comments];

          if (comment.originComment) {
            // we have deleted a reply to a thread
            const { originComment } = comment;

            const parentCommentIndex = updatedComments.findIndex(
              (oldComment) => oldComment.id === originComment.id
            );
            const parentComment = updatedComments[parentCommentIndex];
            const updatedReplies = parentComment.replies.map((reply) => {
              if (reply.id === deletedCommentId) {
                return {
                  ...reply,
                  deletedAt: new Date().toString(),
                };
              }
              return reply;
            });
            updatedComments.splice(parentCommentIndex, 1, {
              ...parentComment,
              replies: updatedReplies,
              totalReplies: parentComment.totalReplies - 1,
            });
            console.log("updatedComments", updatedComments);
          } else {
            // we have deleted a thread itself
            updatedComments = updatedComments.map((reply) => {
              if (reply.id === deletedCommentId) {
                return {
                  ...reply,
                  deletedAt: new Date().toString(),
                };
              }
              return reply;
            });
          }
          store.writeQuery({
            query: COMMENTS_THREADS_WITH_REPLIES,
            variables: {
              eventUUID: this.event.uuid,
            },
            data: {
              event: {
                ...event,
                comments: updatedComments,
              },
            },
          });
        },
      });
      // this.comments = this.comments.filter(commentItem => commentItem.id !== comment.id);
    } catch (error: any) {
      console.error(error);
      if (error.graphQLErrors && error.graphQLErrors.length > 0) {
        this.$notifier.error(error.graphQLErrors[0].message);
      }
    }
  }

  get orderedComments(): IComment[] {
    return this.comments
      .filter((comment) => comment.inReplyToComment == null)
      .sort((a, b) => {
        if (a.isAnnouncement !== b.isAnnouncement) {
          return (
            (b.isAnnouncement === true ? 1 : 0) -
            (a.isAnnouncement === true ? 1 : 0)
          );
        }
        if (a.publishedAt && b.publishedAt) {
          return (
            new Date(b.publishedAt).getTime() -
            new Date(a.publishedAt).getTime()
          );
        } else if (a.updatedAt && b.updatedAt) {
          return (
            new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime()
          );
        }
        return 0;
      });
  }

  get filteredOrderedComments(): IComment[] {
    return this.orderedComments.filter(
      (comment) => !comment.deletedAt || comment.totalReplies > 0
    );
  }

  get isEventOrganiser(): boolean {
    const organizerId =
      this.event?.organizerActor?.id || this.event?.attributedTo?.id;
    return organizerId !== undefined && this.currentActor?.id === organizerId;
  }

  get areCommentsClosed(): boolean {
    return (
      this.currentActor.id !== undefined &&
      this.event.options.commentModeration !== CommentModeration.CLOSED
    );
  }

  get isAbleToComment(): boolean {
    if (this.isConnected) {
      return this.areCommentsClosed || this.isEventOrganiser;
    }
    return false;
  }

  get isConnected(): boolean {
    return this.currentActor?.id != undefined;
  }
}
</script>

<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
form.new-comment {
  padding-bottom: 1rem;

  .media-content {
    display: flex;
    align-items: center;
    align-content: center;

    .field {
      flex: 1;
      @include padding-right(10px);
      margin-bottom: 0;

      &.notify-participants {
        margin-top: 0.5rem;
      }
    }
  }
}

.no-comments {
  display: flex;
  flex-direction: column;

  span {
    text-align: center;
    margin-bottom: 10px;
  }

  img {
    max-width: 250px;
    align-self: center;
  }
}

ul.comment-list li {
  margin-bottom: 16px;
}

.comment-list-enter-active,
.comment-list-leave-active,
.comment-list-move {
  transition: 500ms cubic-bezier(0.59, 0.12, 0.34, 0.95);
  transition-property: opacity, transform;
}

.comment-list-enter {
  opacity: 0;
  transform: translateX(50px) scaleY(0.5);
}

.comment-list-enter-to {
  opacity: 1;
  transform: translateX(0) scaleY(1);
}

.comment-list-leave-active,
.comment-empty-list-active {
  position: absolute;
}

.comment-list-leave-to,
.comment-empty-list-leave-to {
  opacity: 0;
  transform: scaleY(0);
  transform-origin: center top;
}

/*.comment-empty-list-enter-active {*/
/*    transition: opacity .5s;*/
/*}*/

/*.comment-empty-list-enter {*/
/*    opacity: 0;*/
/*}*/
</style>
