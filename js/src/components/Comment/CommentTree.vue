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
        <figure class="media-left">
          <identity-picker-wrapper :inline="false" v-model="newComment.actor" />
        </figure>
        <div class="media-content">
          <div class="field">
            <p class="control">
              <editor
                ref="commenteditor"
                mode="comment"
                v-model="newComment.text"
              />
            </p>
          </div>
          <div class="send-comment">
            <b-button
              native-type="submit"
              type="is-primary"
              class="comment-button-submit"
              >{{ $t("Post a comment") }}</b-button
            >
          </div>
        </div>
      </article>
    </form>
    <b-notification v-else :closable="false">{{
      $t("The organiser has chosen to close comments.")
    }}</b-notification>
    <p
      v-if="$apollo.queries.comments.loading"
      class="loading has-text-centered"
    >
      {{ $t("Loading comments…") }}
    </p>
    <transition name="comment-empty-list" mode="out-in" v-else>
      <transition-group
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
      <div v-else-if="isAbleToComment" class="no-comments">
        <span>{{ $t("No comments yet") }}</span>
      </div>
    </transition>
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
  COMMENTS_THREADS,
  FETCH_THREAD_REPLIES,
} from "../../graphql/comment";
import { CURRENT_ACTOR_CLIENT } from "../../graphql/actor";
import { IPerson } from "../../types/actor";
import { IEvent } from "../../types/event.model";

@Component({
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
    comments: {
      query: COMMENTS_THREADS,
      variables() {
        return {
          eventUUID: this.event.uuid,
        };
      },
      update(data) {
        return data.event.comments.map(
          (comment: IComment) => new CommentModel(comment)
        );
      },
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

  @Watch("currentActor")
  watchCurrentActor(currentActor: IPerson): void {
    this.newComment.actor = currentActor;
  }

  async createCommentForEvent(comment: IComment): Promise<void> {
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
        },
        update: (store, { data }) => {
          if (data == null) return;
          const newComment = data.createComment;

          // comments are attached to the event, so we can pass it to replies later
          newComment.event = this.event;

          // we load all existing threads
          const commentThreadsData = store.readQuery<{ event: IEvent }>({
            query: COMMENTS_THREADS,
            variables: {
              eventUUID: this.event.uuid,
            },
          });
          if (!commentThreadsData) return;
          const { event } = commentThreadsData;
          const { comments: oldComments } = event;

          // if it's no a root comment, we first need to find
          // existing replies and add the new reply to it
          if (comment.originComment !== undefined) {
            const { originComment } = comment;
            const parentCommentIndex = oldComments.findIndex(
              (oldComment) => oldComment.id === originComment.id
            );
            const parentComment = oldComments[parentCommentIndex];

            let oldReplyList: IComment[] = [];
            try {
              const threadData = store.readQuery<{ thread: IComment[] }>({
                query: FETCH_THREAD_REPLIES,
                variables: {
                  threadId: parentComment.id,
                },
              });
              if (!threadData) return;
              oldReplyList = threadData.thread;
            } catch (e) {
              // This simply means there's no loaded replies yet
            } finally {
              oldReplyList.push(newComment);

              // save the updated list of replies (with the one we've just added)
              store.writeQuery({
                query: FETCH_THREAD_REPLIES,
                data: { thread: oldReplyList },
                variables: {
                  threadId: parentComment.id,
                },
              });

              // replace the root comment with has the updated list of replies in the thread list
              parentComment.replies = oldReplyList;
              event.comments.splice(parentCommentIndex, 1, parentComment);
            }
          } else {
            // otherwise it's simply a new thread and we add it to the list
            oldComments.push(newComment);
          }

          // finally we save the thread list
          event.comments = oldComments;
          store.writeQuery({
            query: COMMENTS_THREADS,
            data: { event },
            variables: {
              eventUUID: this.event.uuid,
            },
          });
        },
      });

      // and reset the new comment field
      this.newComment = new CommentModel();
    } catch (error) {
      console.error(error);
      if (error.graphQLErrors && error.graphQLErrors.length > 0) {
        this.$notifier.error(error.graphQLErrors[0].message);
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
        update: (store, { data }) => {
          if (data == null) return;
          const deletedCommentId = data.deleteComment.id;

          const commentsData = store.readQuery<{ event: IEvent }>({
            query: COMMENTS_THREADS,
            variables: {
              eventUUID: this.event.uuid,
            },
          });
          if (!commentsData) return;
          const { event } = commentsData;
          const { comments: oldComments } = event;

          if (comment.originComment) {
            // we have deleted a reply to a thread
            const localData = store.readQuery<{ thread: IComment[] }>({
              query: FETCH_THREAD_REPLIES,
              variables: {
                threadId: comment.originComment.id,
              },
            });
            if (!localData) return;
            const { thread: oldReplyList } = localData;
            const replies = oldReplyList.filter(
              (reply) => reply.id !== deletedCommentId
            );
            store.writeQuery({
              query: FETCH_THREAD_REPLIES,
              variables: {
                threadId: comment.originComment.id,
              },
              data: { thread: replies },
            });

            const { originComment } = comment;

            const parentCommentIndex = oldComments.findIndex(
              (oldComment) => oldComment.id === originComment.id
            );
            const parentComment = oldComments[parentCommentIndex];
            parentComment.replies = replies;
            parentComment.totalReplies -= 1;
            oldComments.splice(parentCommentIndex, 1, parentComment);
            event.comments = oldComments;
          } else {
            // we have deleted a thread itself
            event.comments = oldComments.filter(
              (reply) => reply.id !== deletedCommentId
            );
          }
          store.writeQuery({
            query: COMMENTS_THREADS,
            variables: {
              eventUUID: this.event.uuid,
            },
            data: { event },
          });
        },
      });
      // this.comments = this.comments.filter(commentItem => commentItem.id !== comment.id);
    } catch (error) {
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
        if (a.updatedAt && b.updatedAt) {
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
    if (this.currentActor?.id) {
      return this.areCommentsClosed || this.isEventOrganiser;
    }
    return false;
  }
}
</script>

<style lang="scss" scoped>
form.new-comment {
  padding-bottom: 1rem;

  .media-content {
    display: flex;
    align-items: center;
    align-content: center;

    .field {
      flex: 1;
      padding-right: 10px;
      margin-bottom: 0;
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
