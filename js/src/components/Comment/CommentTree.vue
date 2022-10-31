<template>
  <div>
    <form
      v-if="isAbleToComment"
      @submit.prevent="createCommentForEvent(newComment)"
      class="mt-2"
    >
      <o-notification
        v-if="isEventOrganiser && !areCommentsClosed"
        :closable="false"
        class="my-2"
        >{{ t("Comments are closed for everybody else.") }}</o-notification
      >
      <article class="flex flex-wrap items-start gap-2">
        <figure class="" v-if="newComment.actor">
          <identity-picker-wrapper :inline="false" v-model="newComment.actor" />
        </figure>
        <div class="flex-1">
          <div class="flex flex-col gap-2">
            <div class="editor-wrapper">
              <Editor
                ref="commenteditor"
                v-if="currentActor"
                :currentActor="currentActor"
                mode="comment"
                v-model="newComment.text"
                :aria-label="t('Comment body')"
                @submit="createCommentForEvent(newComment)"
                :placeholder="t('Write a new comment')"
              />
              <p class="" v-if="emptyCommentError">
                {{ t("Comment text can't be empty") }}
              </p>
            </div>
            <div class="" v-if="isEventOrganiser">
              <o-switch
                aria-labelledby="notify-participants-toggle"
                v-model="newComment.isAnnouncement"
                >{{ t("Notify participants") }}</o-switch
              >
            </div>
          </div>
        </div>
        <div class="">
          <o-button native-type="submit" variant="primary" icon-left="send">{{
            t("Send")
          }}</o-button>
        </div>
      </article>
    </form>
    <o-notification v-else-if="isConnected" :closable="false">{{
      t("The organiser has chosen to close comments.")
    }}</o-notification>
    <p v-if="commentsLoading" class="text-center">
      {{ t("Loading comments…") }}
    </p>
    <transition-group tag="div" name="comment-empty-list" v-else class="mt-2">
      <transition-group
        key="list"
        name="comment-list"
        v-if="filteredOrderedComments.length && currentActor"
        class="comment-list"
        tag="ul"
      >
        <event-comment
          class="root-comment my-2"
          :comment="comment"
          :event="event"
          :currentActor="currentActor"
          v-for="comment in filteredOrderedComments"
          :key="comment.id"
          @create-comment="createCommentForEvent"
          @delete-comment="commentToDelete => deleteComment({
              commentId: commentToDelete.id as string,
              originCommentId: commentToDelete.originComment?.id,
            })
          "
        />
      </transition-group>
      <empty-content v-else icon="comment" key="no-comments" :inline="true">
        <span>{{ t("No comments yet") }}</span>
      </empty-content>
    </transition-group>
  </div>
</template>

<script lang="ts" setup>
import EventComment from "@/components/Comment/EventComment.vue";
import IdentityPickerWrapper from "@/views/Account/IdentityPickerWrapper.vue";
import { CommentModeration } from "@/types/enums";
import { CommentModel, IComment } from "../../types/comment.model";
import {
  CREATE_COMMENT_FROM_EVENT,
  DELETE_COMMENT,
  COMMENTS_THREADS_WITH_REPLIES,
} from "../../graphql/comment";
import { IEvent } from "../../types/event.model";
import { ApolloCache, FetchResult, InMemoryCache } from "@apollo/client/core";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { computed, defineAsyncComponent, inject, ref, watch } from "vue";
import { IPerson } from "@/types/actor";
import { AbsintheGraphQLError } from "@/types/errors.model";
import { useI18n } from "vue-i18n";
import { Notifier } from "@/plugins/notifier";

const { currentActor } = useCurrentActorClient();

const { result: commentsResult, loading: commentsLoading } = useQuery<{
  event: Pick<IEvent, "id" | "uuid" | "comments">;
}>(
  COMMENTS_THREADS_WITH_REPLIES,
  () => ({ eventUUID: props.event?.uuid }),
  () => ({ enabled: props.event?.uuid !== undefined })
);

const comments = computed(() => commentsResult.value?.event.comments ?? []);

const props = defineProps<{
  event: IEvent;
  newComment?: IComment;
}>();

const Editor = defineAsyncComponent(
  () => import("@/components/TextEditor.vue")
);

const newComment = ref<IComment>(props.newComment ?? new CommentModel());

const emptyCommentError = ref(false);

const { t } = useI18n({ useScope: "global" });

watch(currentActor, () => {
  newComment.value.actor = currentActor.value as IPerson;
});

watch(newComment, (newCommentUpdated: IComment) => {
  if (emptyCommentError.value) {
    emptyCommentError.value = ["", "<p></p>"].includes(newCommentUpdated.text);
  }
});

const {
  mutate: createCommentForEventMutation,
  onDone: createCommentForEventMutationDone,
  onError: createCommentForEventMutationError,
} = useMutation<
  { createComment: IComment },
  {
    eventId: string;
    text: string;
    inReplyToCommentId?: string;
    isAnnouncement?: boolean;
    originCommentId?: string | undefined;
  }
>(CREATE_COMMENT_FROM_EVENT, () => ({
  update: (
    store: ApolloCache<InMemoryCache>,
    { data }: FetchResult,
    { variables }
  ) => {
    if (data == null) return;
    // comments are attached to the event, so we can pass it to replies later
    const newCommentLocal = { ...data.createComment, event: props.event };

    // we load all existing threads
    const commentThreadsData = store.readQuery<{ event: IEvent }>({
      query: COMMENTS_THREADS_WITH_REPLIES,
      variables: {
        eventUUID: props.event?.uuid,
      },
    });
    if (!commentThreadsData) return;
    const { event } = commentThreadsData;
    const oldComments = [...event.comments];

    // if it's no a root comment, we first need to find
    // existing replies and add the new reply to it
    if (variables?.originCommentId !== undefined) {
      const parentCommentIndex = oldComments.findIndex(
        (oldComment) => oldComment.id === variables.originCommentId
      );
      const parentComment = oldComments[parentCommentIndex];

      // replace the root comment with has the updated list of replies in the thread list
      oldComments.splice(parentCommentIndex, 1, {
        ...parentComment,
        replies: [...parentComment.replies, newCommentLocal],
      });
    } else {
      // otherwise it's simply a new thread and we add it to the list
      oldComments.push(newCommentLocal);
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
        eventUUID: props.event?.uuid,
      },
    });
  },
}));

createCommentForEventMutationDone(() => {
  // and reset the new comment field
  newComment.value = new CommentModel();
});

const notifier = inject<Notifier>("notifier");

createCommentForEventMutationError((errors) => {
  console.error(errors);
  if (errors.graphQLErrors && errors.graphQLErrors.length > 0) {
    const error = errors.graphQLErrors[0] as AbsintheGraphQLError;
    if (error.field !== "text" && error.message[0] !== "can't be blank") {
      notifier?.error(error.message);
    }
  }
});

const createCommentForEvent = (comment: IComment) => {
  emptyCommentError.value = ["", "<p></p>"].includes(comment.text);

  if (emptyCommentError.value) return;
  if (!comment.actor) return;
  if (!props.event?.id) return;

  createCommentForEventMutation({
    eventId: props.event?.id,
    text: comment.text,
    inReplyToCommentId: comment.inReplyToComment?.id,
    isAnnouncement: comment.isAnnouncement,
    originCommentId: comment.originComment?.id,
  });
};

const { mutate: deleteComment, onError: deleteCommentMutationError } =
  useMutation<
    { deleteComment: { id: string } },
    { commentId: string; originCommentId?: string }
  >(DELETE_COMMENT, () => ({
    update: (
      store: ApolloCache<InMemoryCache>,
      { data }: FetchResult,
      { variables }
    ) => {
      if (data == null) return;
      const deletedCommentId = data.deleteComment.id;

      const commentsData = store.readQuery<{ event: IEvent }>({
        query: COMMENTS_THREADS_WITH_REPLIES,
        variables: {
          eventUUID: props.event?.uuid,
        },
      });
      if (!commentsData) return;
      const { event } = commentsData;
      let updatedComments: IComment[] = [...event.comments];

      if (variables?.originCommentId) {
        // we have deleted a reply to a thread
        const parentCommentIndex = updatedComments.findIndex(
          (oldComment) => oldComment.id === variables.originCommentId
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
        console.debug("updatedComments", updatedComments);
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
          eventUUID: props.event?.uuid,
        },
        data: {
          event: {
            ...event,
            comments: updatedComments,
          },
        },
      });
    },
  }));

deleteCommentMutationError((error) => {
  console.error(error);
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

const orderedComments = computed((): IComment[] => {
  return comments.value
    .filter((comment: IComment) => comment.inReplyToComment == null)
    .sort((a: IComment, b: IComment) => {
      if (a.isAnnouncement !== b.isAnnouncement) {
        return (
          (b.isAnnouncement === true ? 1 : 0) -
          (a.isAnnouncement === true ? 1 : 0)
        );
      }
      if (a.publishedAt && b.publishedAt) {
        return (
          new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime()
        );
      } else if (a.updatedAt && b.updatedAt) {
        return (
          new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime()
        );
      }
      return 0;
    });
});

const filteredOrderedComments = computed((): IComment[] => {
  return orderedComments.value.filter(
    (comment) => !comment.deletedAt || comment.totalReplies > 0
  );
});

const isEventOrganiser = computed((): boolean => {
  const organizerId =
    props.event?.organizerActor?.id || props.event?.attributedTo?.id;
  return organizerId !== undefined && currentActor.value?.id === organizerId;
});

const areCommentsClosed = computed((): boolean => {
  return (
    currentActor.value?.id !== undefined &&
    props.event?.options.commentModeration !== CommentModeration.CLOSED
  );
});

const isAbleToComment = computed((): boolean => {
  if (isConnected.value) {
    return areCommentsClosed.value || isEventOrganiser.value;
  }
  return false;
});

const isConnected = computed((): boolean => {
  return currentActor.value?.id != undefined;
});
</script>

<style lang="scss" scoped>
// @use "@/styles/_mixins" as *;
// form.new-comment {
//   padding-bottom: 1rem;

//   .media {
//     flex-wrap: wrap;
//     justify-content: center;
//     // .media-left {
//     //   @include >mobile {
//     //     @include margin-right(0.5rem);
//     //     @include margin-left(0.5rem);
//     //   }
//     // }

//     .media-content {
//       display: flex;
//       align-items: center;
//       align-content: center;
//       width: min-content;

//       .field {
//         flex: 1;
//         // @include padding-right(10px);
//         margin-bottom: 0;

//         &.notify-participants {
//           margin-top: 0.5rem;
//         }
//       }
//     }
//   }
// }

// .no-comments {
//   display: flex;
//   flex-direction: column;

//   span {
//     text-align: center;
//     margin-bottom: 10px;
//   }

//   img {
//     max-width: 250px;
//     align-self: center;
//   }
// }

// ul.comment-list li {
//   margin-bottom: 16px;
// }

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

// .comment-empty-list-enter-active {
//     transition: opacity .5s;
// }

// .comment-empty-list-enter {
//     opacity: 0;
// }
</style>
