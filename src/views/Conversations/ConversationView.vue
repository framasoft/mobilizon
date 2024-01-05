<template>
  <div class="container mx-auto" v-if="conversation">
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.CONVERSATION_LIST,
          text: t('Conversations'),
        },
        {
          name: RouteName.CONVERSATION,
          params: { id: conversation.id },
          text: title,
        },
      ]"
    />
    <div
      v-if="
        conversation.event &&
        !isCurrentActorAuthor &&
        isOriginCommentAuthorEventOrganizer
      "
      class="bg-mbz-yellow p-6 mb-3 rounded flex gap-2 items-center"
    >
      <Calendar :size="36" />
      <i18n-t
        tag="p"
        keypath="This is a announcement from the organizers of event {event}. You can't reply to it, but you can send a private message to event organizers."
      >
        <template #event>
          <b>
            <router-link
              :to="{
                name: RouteName.EVENT,
                params: { uuid: conversation.event.uuid },
              }"
              >{{ conversation.event.title }}</router-link
            >
          </b>
        </template>
      </i18n-t>
    </div>
    <o-notification v-if="isCurrentActorAuthor" variant="info" closable>
      <i18n-t
        keypath="You have access to this conversation as a member of the {group} group"
        tag="p"
      >
        <template #group>
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: {
                preferredUsername: usernameWithDomain(conversation.actor),
              },
            }"
            ><b>{{ displayName(conversation.actor) }}</b></router-link
          >
        </template>
      </i18n-t>
    </o-notification>
    <o-notification
      v-else-if="groupParticipants.length > 0 && !conversation.event"
      variant="info"
      closable
    >
      <p>
        {{
          t(
            "The following participants are groups, which means group members are able to reply to this conversation:"
          )
        }}
      </p>
      <ul class="list-disc">
        <li
          v-for="groupParticipant in groupParticipants"
          :key="groupParticipant.id"
        >
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: {
                preferredUsername: usernameWithDomain(groupParticipant),
              },
            }"
            ><b>{{ displayName(groupParticipant) }}</b></router-link
          >
        </li>
      </ul>
    </o-notification>
    <o-notification v-if="error" variant="danger">
      {{ error }}
    </o-notification>
    <section v-if="currentActor">
      <discussion-comment
        v-for="comment in conversation.comments.elements"
        :key="comment.id"
        :model-value="comment"
        :current-actor="currentActor"
        :can-report="true"
        @update:modelValue="
          (comment: IComment) =>
            updateComment({
              commentId: comment.id as string,
              text: comment.text,
            })
        "
        @delete-comment="
          (comment: IComment) =>
            deleteComment({
              commentId: comment.id as string,
            })
        "
      />
      <o-button
        v-if="
          conversation.comments.elements.length < conversation.comments.total
        "
        @click="loadMoreComments"
        >{{ t("Fetch more") }}</o-button
      >
      <form @submit.prevent="reply" v-if="!error && !conversation.event">
        <o-field :label="t('Text')">
          <Editor
            v-model="newComment"
            :aria-label="t('Message body')"
            v-if="currentActor"
            :currentActor="currentActor"
            :placeholder="t('Write a new message')"
          />
        </o-field>
        <o-button
          class="my-2"
          native-type="submit"
          :disabled="['<p></p>', ''].includes(newComment)"
          variant="primary"
          >{{ t("Reply") }}</o-button
        >
      </form>
      <div
        v-else-if="
          conversation.event &&
          !isCurrentActorAuthor &&
          isOriginCommentAuthorEventOrganizer
        "
        class="bg-mbz-yellow p-6 rounded flex gap-2 items-center mt-3"
      >
        <Calendar :size="36" />
        <i18n-t
          tag="p"
          keypath="This is a announcement from the organizers of event {event}. You can't reply to it, but you can send a private message to event organizers."
        >
          <template #event>
            <b>
              <router-link
                :to="{
                  name: RouteName.EVENT,
                  params: { uuid: conversation.event.uuid },
                }"
                >{{ conversation.event.title }}</router-link
              >
            </b>
          </template>
        </i18n-t>
      </div>
    </section>
  </div>
</template>
<script lang="ts" setup>
import {
  CONVERSATION_COMMENT_CHANGED,
  GET_CONVERSATION,
  MARK_CONVERSATION_AS_READ,
  REPLY_TO_PRIVATE_MESSAGE_MUTATION,
} from "../../graphql/conversations";
import DiscussionComment from "../../components/Discussion/DiscussionComment.vue";
import { DELETE_COMMENT, UPDATE_COMMENT } from "../../graphql/comment";
import RouteName from "../../router/name";
import { IComment } from "../../types/comment.model";
import {
  ApolloCache,
  FetchResult,
  InMemoryCache,
  gql,
} from "@apollo/client/core";
import { useMutation, useQuery } from "@vue/apollo-composable";
import {
  defineAsyncComponent,
  ref,
  computed,
  onMounted,
  onUnmounted,
} from "vue";
import { useHead } from "@unhead/vue";
import { useRouter } from "vue-router";
import { useCurrentActorClient } from "../../composition/apollo/actor";
import { AbsintheGraphQLError } from "../../types/errors.model";
import { useI18n } from "vue-i18n";
import { IConversation } from "@/types/conversation";
import { usernameWithDomain, displayName } from "@/types/actor";
import { formatList } from "@/utils/i18n";
import throttle from "lodash/throttle";
import Calendar from "vue-material-design-icons/Calendar.vue";
import { ActorType } from "@/types/enums";

const props = defineProps<{ id: string }>();

const conversationId = computed(() => props.id);

const page = ref(1);
const COMMENTS_PER_PAGE = 10;

const { currentActor } = useCurrentActorClient();

const {
  result: conversationResult,
  onResult: onConversationResult,
  onError: onConversationError,
  subscribeToMore,
  fetchMore,
} = useQuery<{ conversation: IConversation }>(
  GET_CONVERSATION,
  () => ({
    id: conversationId.value,
    page: page.value,
    limit: COMMENTS_PER_PAGE,
  }),
  () => ({
    enabled: conversationId.value !== undefined,
  })
);

subscribeToMore({
  document: CONVERSATION_COMMENT_CHANGED,
  variables: {
    id: conversationId.value,
  },
  updateQuery(
    previousResult: any,
    { subscriptionData }: { subscriptionData: any }
  ) {
    const previousConversation = previousResult.conversation;
    const lastComment =
      subscriptionData.data.conversationCommentChanged.lastComment;
    hasMoreComments.value = !previousConversation.comments.elements.some(
      (comment: IComment) => comment.id === lastComment.id
    );
    if (hasMoreComments.value) {
      return {
        conversation: {
          ...previousConversation,
          lastComment: lastComment,
          comments: {
            elements: [
              ...previousConversation.comments.elements.filter(
                ({ id }: { id: string }) => id !== lastComment.id
              ),
              lastComment,
            ],
            total: previousConversation.comments.total + 1,
          },
        },
      };
    }

    return previousConversation;
  },
});

const conversation = computed(() => conversationResult.value?.conversation);
const otherParticipants = computed(
  () =>
    conversation.value?.participants.filter(
      (participant) => participant.id !== currentActor.value?.id
    ) ?? []
);

const groupParticipants = computed(() => {
  return otherParticipants.value.filter(
    (participant) => participant.type === ActorType.GROUP
  );
});

const Editor = defineAsyncComponent(
  () => import("../../components/TextEditor.vue")
);

const { t } = useI18n({ useScope: "global" });

const title = computed(() =>
  t("Conversation with {participants}", {
    participants: formatList(
      otherParticipants.value.map((participant) => displayName(participant))
    ),
  })
);

const isCurrentActorAuthor = computed(
  () =>
    currentActor.value &&
    conversation.value &&
    currentActor.value.id !== conversation.value?.actor?.id
);

const isOriginCommentAuthorEventOrganizer = computed(
  () =>
    conversation.value?.originComment?.actor &&
    conversation.value?.event &&
    [
      conversation.value?.event?.organizerActor?.id,
      conversation.value?.event?.attributedTo?.id,
    ].includes(conversation.value?.originComment?.actor.id)
);

useHead({
  title: () => title.value,
});

const newComment = ref("");
// const newTitle = ref("");
// const editTitleMode = ref(false);
const hasMoreComments = ref(true);
const error = ref<string | null>(null);

const { mutate: replyToConversationMutation } = useMutation<
  {
    postPrivateMessage: IConversation;
  },
  {
    text: string;
    actorId: string;
    language?: string;
    conversationId: string;
    mentions?: string[];
    attributedToId?: string;
  }
>(REPLY_TO_PRIVATE_MESSAGE_MUTATION, () => ({
  update: (store: ApolloCache<InMemoryCache>, { data }) => {
    console.debug("update after reply to", [conversationId.value, page.value]);
    const conversationData = store.readQuery<{
      conversation: IConversation;
    }>({
      query: GET_CONVERSATION,
      variables: {
        id: conversationId.value,
      },
    });
    console.debug("update after reply to", conversationData);
    if (!conversationData) return;
    const { conversation: conversationCached } = conversationData;

    console.debug("got cache", conversationCached);

    store.writeQuery({
      query: GET_CONVERSATION,
      variables: {
        id: conversationId.value,
      },
      data: {
        conversation: {
          ...conversationCached,
          lastComment: data?.postPrivateMessage.lastComment,
          comments: {
            elements: [
              ...conversationCached.comments.elements,
              data?.postPrivateMessage.lastComment,
            ],
            total: conversationCached.comments.total + 1,
          },
        },
      },
    });
  },
}));

const reply = () => {
  if (
    newComment.value === "" ||
    !conversation.value?.id ||
    !currentActor.value?.id
  )
    return;

  replyToConversationMutation({
    conversationId: conversation.value?.id,
    text: newComment.value,
    actorId: currentActor.value?.id,
    mentions: otherParticipants.value.map((participant) =>
      usernameWithDomain(participant)
    ),
    attributedToId:
      conversation.value?.actor?.type === ActorType.GROUP
        ? conversation.value?.actor.id
        : undefined,
  });

  newComment.value = "";
};

const { mutate: updateComment } = useMutation<
  { updateComment: IComment },
  { commentId: string; text: string }
>(UPDATE_COMMENT, () => ({
  update: (
    store: ApolloCache<{ deleteComment: IComment }>,
    { data }: FetchResult
  ) => {
    if (!data || !data.deleteComment) return;
    const discussionData = store.readQuery<{
      conversation: IConversation;
    }>({
      query: GET_CONVERSATION,
      variables: {
        id: conversationId.value,
        page: page.value,
      },
    });
    if (!discussionData) return;
    const { conversation: discussionCached } = discussionData;
    const index = discussionCached.comments.elements.findIndex(
      ({ id }) => id === data.deleteComment.id
    );
    if (index > -1) {
      discussionCached.comments.elements.splice(index, 1);
      discussionCached.comments.total -= 1;
    }
    store.writeQuery({
      query: GET_CONVERSATION,
      variables: { id: conversationId.value, page: page.value },
      data: { conversation: discussionCached },
    });
  },
}));

const { mutate: deleteComment } = useMutation<
  { deleteComment: { id: string } },
  { commentId: string }
>(DELETE_COMMENT, () => ({
  update: (store: ApolloCache<{ deleteComment: IComment }>, { data }) => {
    const id = data?.deleteComment?.id;
    if (!id) return;
    store.writeFragment({
      id: `Comment:${id}`,
      fragment: gql`
        fragment CommentDeleted on Comment {
          deletedAt
          actor {
            id
          }
          text
        }
      `,
      data: {
        deletedAt: new Date(),
        text: "",
        actor: null,
      },
    });
  },
}));

const loadMoreComments = async (): Promise<void> => {
  if (!hasMoreComments.value) return;
  console.debug("Loading more comments");
  page.value++;
  try {
    await fetchMore({
      // New variables
      variables: () => ({
        id: conversationId.value,
        page: page.value,
        limit: COMMENTS_PER_PAGE,
      }),
    });
    hasMoreComments.value = !conversation.value?.comments.elements
      .map(({ id }) => id)
      .includes(conversation.value?.lastComment?.id);
  } catch (e) {
    console.error(e);
  }
};

// const dialog = inject<Dialog>("dialog");

// const openDeleteDiscussionConfirmation = (): void => {
//   dialog?.confirm({
//     variant: "danger",
//     title: t("Delete this conversation"),
//     message: t("Are you sure you want to delete this entire conversation?"),
//     confirmText: t("Delete conversation"),
//     cancelText: t("Cancel"),
//     onConfirm: () =>
//       deleteConversation({
//         discussionId: conversation.value?.id,
//       }),
//   });
// };

const router = useRouter();

// const { mutate: deleteConversation, onDone: deleteConversationDone } =
//   useMutation(DELETE_DISCUSSION);

// deleteConversationDone(() => {
//   if (conversation.value?.actor) {
//     router.push({
//       name: RouteName.DISCUSSION_LIST,
//       params: {
//         preferredUsername: usernameWithDomain(conversation.value.actor),
//       },
//     });
//   }
// });

onConversationError((discussionError) =>
  handleErrors(discussionError.graphQLErrors as AbsintheGraphQLError[])
);

onConversationResult(({ data }) => {
  if (
    page.value === 1 &&
    data?.conversation?.comments?.total &&
    data?.conversation?.comments?.total < COMMENTS_PER_PAGE
  ) {
    markConversationAsRead();
  }
});

const handleErrors = async (errors: AbsintheGraphQLError[]): Promise<void> => {
  if (errors[0].code === "not_found") {
    await router.push({ name: RouteName.PAGE_NOT_FOUND });
  }
  if (errors[0].code === "unauthorized") {
    error.value = errors[0].message;
  }
};

onMounted(() => {
  window.addEventListener("scroll", handleScroll);
});

onUnmounted(() => {
  window.removeEventListener("scroll", handleScroll);
});

const { mutate: markConversationAsRead } = useMutation<
  {
    updateConversation: IConversation;
  },
  {
    id: string;
    read: boolean;
  }
>(MARK_CONVERSATION_AS_READ, {
  variables: {
    id: conversationId.value,
    read: true,
  },
});

const loadMoreCommentsThrottled = throttle(async () => {
  console.log("Throttled");
  await loadMoreComments();
  if (!hasMoreComments.value && conversation.value?.unread) {
    console.debug("marking as read");
    markConversationAsRead();
  }
}, 1000);

const handleScroll = (): void => {
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
    console.debug("Scrolled to bottom");
    loadMoreCommentsThrottled();
  }
};
</script>
