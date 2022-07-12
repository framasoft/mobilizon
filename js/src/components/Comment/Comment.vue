<template>
  <li
    :class="{
      reply: comment.inReplyToComment,
      'bg-purple-2': comment.isAnnouncement,
      'bg-violet-1': commentSelected,
      'shadow-none': !rootComment,
    }"
    class="mbz-card p-2"
  >
    <article :id="commentId" dir="auto">
      <div>
        <div class="flex items-center gap-2">
          <div class="flex items-center gap-1" v-if="actorComment">
            <popover-actor-card
              :actor="actorComment"
              :inline="true"
              v-if="!comment.deletedAt && actorComment.avatar"
            >
              <figure>
                <img
                  class="rounded-xl"
                  :src="actorComment.avatar.url"
                  alt=""
                  width="24"
                  height="24"
                />
              </figure>
            </popover-actor-card>
            <AccountCircle v-else />
            <strong
              v-if="!comment.deletedAt"
              dir="auto"
              :class="{ organizer: commentFromOrganizer }"
              >{{ actorComment?.name }}</strong
            >
          </div>

          <a v-else :href="commentURL">
            <span>{{ t("[deleted]") }}</span>
          </a>
          <a :href="commentURL">
            <small v-if="comment.updatedAt">{{
              formatDistanceToNow(new Date(comment.updatedAt), {
                locale: dateFnsLocale,
                addSuffix: true,
              })
            }}</small>
          </a>
          <div v-if="!comment.deletedAt" class="flex">
            <button
              v-if="actorComment?.id === currentActor?.id"
              @click="deleteComment"
            >
              <Delete :size="16" />
              <span class="sr-only">{{ t("Delete") }}</span>
            </button>
            <button @click="reportModal">
              <Alert :size="16" />
              <span class="sr-only">{{ t("Report") }}</span>
            </button>
          </div>
        </div>
        <div
          v-if="!comment.deletedAt"
          v-html="comment.text"
          dir="auto"
          :lang="comment.language"
        />
        <div v-else>{{ t("[This comment has been deleted]") }}</div>
        <div class="" v-if="comment.totalReplies">
          <p
            v-if="!showReplies"
            @click="showReplies = true"
            class="flex cursor-pointer"
          >
            <ChevronDown />
            <span>{{
              t(
                "View a reply",
                {
                  totalReplies: comment.totalReplies,
                },
                comment.totalReplies
              )
            }}</span>
          </p>
          <p
            v-else-if="comment.totalReplies && showReplies"
            @click="showReplies = false"
            class="flex cursor-pointer"
          >
            <ChevronUp />
            <span>{{ t("Hide replies") }}</span>
          </p>
        </div>
        <nav
          v-if="
            currentActor?.id &&
            event.options.commentModeration !== CommentModeration.CLOSED &&
            !comment.deletedAt
          "
          @click="createReplyToComment()"
          class="flex gap-1 cursor-pointer"
        >
          <Reply />
          <span>{{ t("Reply") }}</span>
        </nav>
      </div>
    </article>
    <form
      @submit.prevent="replyToComment"
      v-if="currentActor?.id"
      v-show="replyTo"
    >
      <article class="flex gap-2">
        <figure v-if="currentActor?.avatar" class="mt-4">
          <img
            :src="currentActor?.avatar.url"
            alt=""
            width="48"
            height="48"
            class="rounded-md"
          />
        </figure>
        <AccountCircle v-else :size="48" />
        <div class="flex-1">
          <div class="flex gap-1 items-center">
            <strong>{{ currentActor?.name }}</strong>
            <small dir="ltr">@{{ currentActor?.preferredUsername }}</small>
          </div>
          <div class="flex flex-col gap-2">
            <editor
              ref="commentEditor"
              v-model="newComment.text"
              mode="comment"
              :current-actor="currentActor"
              :aria-label="t('Comment body')"
              class="flex-1"
            />
            <o-button
              :disabled="newComment.text.trim().length === 0"
              native-type="submit"
              variant="primary"
              class="self-end"
              >{{ t("Post a reply") }}</o-button
            >
          </div>
        </div>
      </article>
    </form>
    <div>
      <div>
        <div @click="showReplies = false" />
      </div>
      <transition-group
        name="comment-replies"
        v-if="showReplies"
        tag="ul"
        class="flex flex-col gap-2"
      >
        <Comment
          v-for="reply in comment.replies"
          :key="reply.id"
          :comment="reply"
          :event="event"
          :currentActor="currentActor"
          :rootComment="false"
          @create-comment="emit('create-comment', $event)"
          @delete-comment="emit('delete-comment', $event)"
          @report-comment="emit('report-comment', $event)"
        />
      </transition-group>
    </div>
  </li>
</template>
<script lang="ts" setup>
import EditorComponent from "@/components/Editor.vue";
import { formatDistanceToNow } from "date-fns";
import { CommentModeration } from "@/types/enums";
import { CommentModel, IComment } from "../../types/comment.model";
import { IPerson } from "../../types/actor";
import { IEvent } from "../../types/event.model";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import {
  computed,
  defineAsyncComponent,
  inject,
  onMounted,
  ref,
  nextTick,
} from "vue";
import { useRoute } from "vue-router";
import { useI18n } from "vue-i18n";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import Delete from "vue-material-design-icons/Delete.vue";
import Alert from "vue-material-design-icons/Alert.vue";
import ChevronUp from "vue-material-design-icons/ChevronUp.vue";
import ChevronDown from "vue-material-design-icons/ChevronDown.vue";
import Reply from "vue-material-design-icons/Reply.vue";

const Editor = defineAsyncComponent(() => import("@/components/Editor.vue"));

const props = withDefaults(
  defineProps<{
    comment: IComment;
    event: IEvent;
    currentActor: IPerson;
    rootComment?: boolean;
  }>(),
  { rootComment: true }
);

const emit = defineEmits([
  "create-comment",
  "delete-comment",
  "report-comment",
]);

const commentEditor = ref<typeof EditorComponent | null>(null);

// Hack because Vue only exports it's own interface.
// See https://github.com/kaorun343/vue-property-decorator/issues/257
// @Ref() readonly commentEditor!: EditorComponent & {
//   replyToComment: (comment: IComment) => void;
//   focus: () => void;
// };

const newComment = ref<IComment>(new CommentModel());
const replyTo = ref(false);
const showReplies = ref(false);
const route = useRoute();
const { t } = useI18n({ useScope: "global" });

onMounted(() => {
  if (route?.hash.includes(`#comment-${props.comment.uuid}`)) {
    showReplies.value = true;
  }
});

const createReplyToComment = async (): Promise<void> => {
  if (replyTo.value) {
    replyTo.value = false;
    newComment.value = new CommentModel();
    return;
  }
  replyTo.value = true;
  if (props.comment.actor) {
    commentEditor.value?.replyToComment(props.comment.actor);
    await nextTick(); // wait for the mention to be injected
    commentEditor.value?.focus();
  }
};

const replyToComment = (): void => {
  newComment.value.inReplyToComment = props.comment;
  newComment.value.originComment = props.comment.originComment ?? props.comment;
  newComment.value.actor = props.currentActor;
  console.log(newComment.value);
  emit("create-comment", newComment.value);
  newComment.value = new CommentModel();
  replyTo.value = false;
  showReplies.value = true;
};

const deleteComment = (): void => {
  emit("delete-comment", props.comment);
  showReplies.value = false;
};

const commentSelected = computed((): boolean => {
  return `#${commentId.value}` === route?.hash;
});

const commentFromOrganizer = computed((): boolean => {
  const organizerId =
    props.event?.organizerActor?.id || props.event?.attributedTo?.id;
  return organizerId !== undefined && props.comment?.actor?.id === organizerId;
});

const commentId = computed((): string => {
  if (props.comment.originComment)
    return `comment-${props.comment.originComment.uuid}-${props.comment.uuid}`;
  return `comment-${props.comment.uuid}`;
});

const commentURL = computed((): string => {
  if (!props.comment.local && props.comment.url) return props.comment.url;
  return `#${commentId.value}`;
});

const reportModal = (): void => {
  if (!props.comment.actor) return;
  emit("report-comment", props.comment);
  // this.$buefy.modal.open({
  //   component: ReportModal,
  //   props: {
  //     title: t("Report this comment"),
  //     comment: props.comment,
  //     onConfirm: reportComment,
  //     outsideDomain: props.comment.actor?.domain,
  //   },
  //   // https://github.com/buefy/buefy/pull/3589
  //   // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  //   // @ts-ignore
  //   closeButtonAriaLabel: this.t("Close"),
  // });
};

// const reportComment = async (
//   content: string,
//   forward: boolean
// ): Promise<void> => {
//   try {
//     if (!props.comment.actor) return;

//     const { onError, onDone } = useMutation(CREATE_REPORT, () => ({
//       variables: {
//         eventId: props.event.id,
//         reportedId: props.comment.actor?.id,
//         commentsIds: [props.comment.id],
//         content,
//         forward,
//       },
//     }));

//     // this.$buefy.notification.open({
//     //   message: this.t("Comment from @{username} reported", {
//     //     username: this.comment.actor.preferredUsername,
//     //   }) as string,
//     //   type: "is-success",
//     //   position: "is-bottom-right",
//     //   duration: 5000,
//     // });
//   } catch (e: any) {
//     if (e.message) {
//       // Snackbar.open({
//       //   message: e.message,
//       //   type: "is-danger",
//       //   position: "is-bottom",
//       // });
//     }
//   }
// };
const actorComment = computed(() => props.comment.actor);
const dateFnsLocale = inject<Locale>("dateFnsLocale");
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
form.reply {
  padding-bottom: 1rem;
}

.first-line {
  margin-bottom: 3px;

  * {
    padding: 0 5px 0 0;
  }

  strong.organizer {
    background: $background-color;
    border-radius: 12px;
    color: white;
    padding: 0 6px;
  }

  // & > small {
  //   @include margin-left(0.3rem);
  // }
}

.editor-line {
  display: flex;
  max-width: calc(80rem - 64px);

  .editor {
    flex: 1;
    // @include padding-right(10px);
    margin-bottom: 0;
  }
}

a.comment-link {
  text-decoration: none;
  // @include margin-left(5px);
  color: text;
  &:hover {
    text-decoration: underline;
  }
  small {
    &:hover {
      color: hsl(0, 0%, 21%);
    }
  }
}

.comment-element {
  padding: 0.25rem;
  border-radius: 5px;

  &.announcement {
    background: $purple-2;

    small {
      color: hsl(0, 0%, 21%);
    }
  }

  &.selected {
    background-color: $violet-1;
    color: $white;
    .reply-btn,
    small,
    span,
    strong,
    .icons button {
      color: $white;
    }
    a.comment-link:hover {
      text-decoration: underline;
      text-decoration-color: $white;
      small {
        color: $purple-3;
      }
    }
  }

  // .media-left {
  //   @include margin-right(5px);
  // }
}

.root-comment .replies {
  display: flex;

  .left {
    display: flex;
    flex-direction: column;
    align-items: center;
    // @include margin-right(10px);

    .vertical-border {
      width: 3px;
      height: 100%;
      background-color: rgba(0, 0, 0, 0.05);
      margin: 10px calc(1rem + 1px);
      cursor: pointer;

      &:hover {
        background-color: rgba(0, 0, 0, 0.1);
      }
    }
  }
}

.media .media-content {
  overflow-x: initial;
  .content {
    text-align: start;
    .editor-line {
      display: flex;
      align-items: center;
    }
  }

  .icons {
    display: none;
  }
}

.media:hover .media-content .icons {
  display: inline;

  button {
    cursor: pointer;
    border: none;
    background: none;
  }
}

.load-replies {
  cursor: pointer;

  & > p > span {
    font-weight: bold;
    color: $violet-2;
  }
}

.level-item.reply-btn {
  font-weight: bold;
  color: $violet-2;
}

article {
  border-radius: 4px;
  margin-bottom: 5px;
}

.comment-replies {
  flex-grow: 1;
}

.comment-replies-enter-active,
.comment-replies-leave-active,
.comment-replies-move {
  transition: 500ms cubic-bezier(0.59, 0.12, 0.34, 0.95);
  transition-property: opacity, transform;
}

.comment-replies-enter {
  opacity: 0;
  transform: translateX(50px) scaleY(0.5);
}

.comment-replies-enter-to {
  opacity: 1;
  transform: translateX(0) scaleY(1);
}

.comment-replies-leave-active {
  position: absolute;
}

.comment-replies-leave-to {
  opacity: 0;
  transform: scaleY(0);
  transform-origin: center top;
}

// .reply-action .icon {
//   @include padding-right(0.4rem);
// }

.visually-hidden {
  display: none;
}
</style>
