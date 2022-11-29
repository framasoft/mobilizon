<template>
  <li
    class="bg-white dark:bg-zinc-800 rounded p-2"
    :class="{
      reply: comment.inReplyToComment,
      'bg-mbz-purple-50 dark:bg-mbz-purple-500': comment.isAnnouncement,
      'bg-mbz-bluegreen-50 dark:bg-mbz-bluegreen-600': commentSelected,
      'shadow-none': !rootComment,
    }"
  >
    <article :id="commentId" dir="auto" class="mbz-comment">
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

          <p v-else :href="commentURL">
            <span>{{ t("[deleted]") }}</span>
          </p>
          <a :href="commentURL">
            <small v-if="comment.updatedAt">{{
              formatDistanceToNow(new Date(comment.updatedAt), {
                locale: dateFnsLocale,
                addSuffix: true,
              })
            }}</small>
          </a>
        </div>
        <div
          v-if="!comment.deletedAt"
          v-html="comment.text"
          dir="auto"
          :lang="comment.language"
          class="prose dark:prose-invert xl:prose-lg !max-w-full"
          :class="{ 'text-black dark:text-white': comment.isAnnouncement }"
        />
        <div v-else>{{ t("[This comment has been deleted]") }}</div>
        <nav class="flex gap-1 mt-1" v-if="!comment.deletedAt">
          <button
            class="cursor-pointer flex hover:bg-zinc-300 dark:hover:bg-zinc-600 rounded p-1"
            v-if="
              currentActor?.id &&
              event.options.commentModeration !== CommentModeration.CLOSED &&
              !comment.deletedAt
            "
            @click="createReplyToComment()"
          >
            <Reply />
            <span>{{ t("Reply") }}</span>
          </button>
          <o-dropdown aria-role="list">
            <template #trigger>
              <button
                class="cursor-pointer flex hover:bg-zinc-300 dark:hover:bg-zinc-600 rounded p-1"
              >
                <DotsHorizontal />
                <span class="sr-only">{{ t("More options") }}</span>
              </button>
            </template>
            <o-dropdown-item
              aria-role="listitem"
              v-if="actorComment?.id === currentActor?.id"
            >
              <button class="flex items-center gap-1" @click="deleteComment">
                <Delete :size="16" />
                <span>{{ t("Delete") }}</span>
              </button>
            </o-dropdown-item>
            <o-dropdown-item aria-role="listitem">
              <button
                @click="isReportModalActive = true"
                class="flex items-center gap-1"
              >
                <Alert :size="16" />
                <span>{{ t("Report") }}</span>
              </button>
            </o-dropdown-item>
          </o-dropdown>
        </nav>
        <div class="" v-if="comment.totalReplies">
          <button
            v-if="!showReplies"
            @click="showReplies = true"
            class="flex cursor-pointer hover:bg-zinc-300 dark:hover:bg-zinc-600 rounded p-1"
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
          </button>
          <button
            v-else-if="comment.totalReplies && showReplies"
            @click="showReplies = false"
            class="flex cursor-pointer hover:bg-zinc-300 dark:hover:bg-zinc-600 rounded p-1"
          >
            <ChevronUp />
            <span>{{ t("Hide replies") }}</span>
          </button>
        </div>
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
              @submit="replyToComment"
              :placeholder="t('Write a new reply')"
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
    <transition-group
      name="comment-replies"
      v-if="showReplies"
      tag="ul"
      class="flex flex-col gap-2"
    >
      <EventComment
        v-for="reply in comment.replies"
        :key="reply.id"
        :comment="reply"
        :event="event"
        :currentActor="currentActor"
        :rootComment="false"
        @create-comment="emit('create-comment', $event)"
        @delete-comment="emit('delete-comment', $event)"
        @report-comment="emit('report-comment', $event)"
        class="ml-2"
      />
    </transition-group>
    <o-modal
      v-model:active="isReportModalActive"
      has-modal-card
      ref="reportModal"
      :close-button-aria-label="t('Close')"
    >
      <ReportModal
        :on-confirm="reportComment"
        :title="t('Report this comment')"
        :outside-domain="comment.actor?.domain"
      />
    </o-modal>
  </li>
</template>
<script lang="ts" setup>
import type EditorComponent from "@/components/TextEditor.vue";
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
import DotsHorizontal from "vue-material-design-icons/DotsHorizontal.vue";
import Reply from "vue-material-design-icons/Reply.vue";
import type { Locale } from "date-fns";
import ReportModal from "@/components/Report/ReportModal.vue";
import { useCreateReport } from "@/composition/apollo/report";
import { Snackbar } from "@/plugins/snackbar";
import { useProgrammatic } from "@oruga-ui/oruga-next";

const Editor = defineAsyncComponent(
  () => import("@/components/TextEditor.vue")
);

const props = withDefaults(
  defineProps<{
    comment: IComment;
    event: IEvent;
    currentActor: IPerson;
    rootComment?: boolean;
  }>(),
  { rootComment: true }
);

const emit = defineEmits<{
  (e: "create-comment", comment: IComment): void;
  (e: "delete-comment", comment: IComment): void;
  (e: "report-comment", comment: IComment): void;
}>();

const commentEditor = ref<typeof EditorComponent | null>(null);

const newComment = ref<IComment>(new CommentModel());
const replyTo = ref(false);
const showReplies = ref(false);
const route = useRoute();
const { t } = useI18n({ useScope: "global" });
const isReportModalActive = ref(false);

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
  console.debug(newComment.value);
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

const {
  mutate: createReportMutation,
  onError: onCreateReportError,
  onDone: oneCreateReportDone,
} = useCreateReport();

const reportComment = async (
  content: string,
  forward: boolean
): Promise<void> => {
  if (!props.comment.actor) return;
  createReportMutation({
    eventId: props.event.id,
    reportedId: props.comment.actor?.id ?? "",
    commentsIds: [props.comment.id ?? ""],
    content,
    forward,
  });
};

const snackbar = inject<Snackbar>("snackbar");
const { oruga } = useProgrammatic();

onCreateReportError((e) => {
  isReportModalActive.value = false;
  if (e.message) {
    snackbar?.open({
      message: e.message,
      variant: "danger",
      position: "bottom",
    });
  }
});

oneCreateReportDone(() => {
  isReportModalActive.value = false;
  oruga.notification.open({
    message: t("Comment from {'@'}{username} reported", {
      username: props.comment.actor?.preferredUsername,
    }),
    variant: "success",
    position: "bottom-right",
    duration: 5000,
  });
});

const actorComment = computed(() => props.comment.actor);
const dateFnsLocale = inject<Locale>("dateFnsLocale");
</script>
<style>
article.mbz-comment .mention.h-card {
  @apply inline-block border border-zinc-600 dark:border-zinc-300 rounded py-0.5 px-1;
}
</style>
