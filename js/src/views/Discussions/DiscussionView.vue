<template>
  <div class="container mx-auto" v-if="discussion">
    <breadcrumbs-nav
      v-if="group"
      :links="[
        {
          name: RouteName.MY_GROUPS,
          text: t('My groups'),
        },
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
          text: displayName(group),
        },
        {
          name: RouteName.DISCUSSION_LIST,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Discussions'),
        },
        {
          name: RouteName.DISCUSSION,
          params: { id: discussion.id },
          text: discussion.title,
        },
      ]"
    />
    <o-notification v-if="error" variant="danger">
      {{ error }}
    </o-notification>
    <section v-if="currentActor">
      <div class="flex items-center gap-2" dir="auto">
        <h1 class="" v-if="discussion.title && !editTitleMode">
          {{ discussion.title }}
        </h1>
        <o-button
          icon-right="pencil"
          size="small"
          :title="t('Update discussion title')"
          v-if="
            discussion.creator &&
            !editTitleMode &&
            (currentActor?.id === discussion.creator.id ||
              isCurrentActorAGroupModerator)
          "
          @click="
            () => {
              newTitle = discussion?.title ?? '';
              editTitleMode = true;
            }
          "
        >
        </o-button>
        <o-skeleton
          v-else-if="!editTitleMode && discussionLoading"
          height="50px"
          animated
        />
        <form
          v-else-if="!discussionLoading && !error"
          @submit.prevent="updateDiscussion"
          class="w-full"
        >
          <o-field :label="t('Title')" label-for="discussion-title">
            <o-input
              :value="discussion.title"
              v-model="newTitle"
              id="discussion-title"
            />
          </o-field>
          <div class="flex gap-2 mt-2">
            <o-button
              variant="primary"
              native-type="submit"
              icon-right="check"
              :title="t('Update discussion title')"
            />
            <o-button
              @click="
                () => {
                  editTitleMode = false;
                  newTitle = '';
                }
              "
              icon-right="close"
              :title="t('Cancel discussion title edition')"
            />
            <o-button
              @click="openDeleteDiscussionConfirmation"
              variant="danger"
              native-type="button"
              icon-left="delete"
              >{{ t("Delete conversation") }}</o-button
            >
          </div>
        </form>
      </div>
      <discussion-comment
        class="border rounded-md p-2 mt-4"
        v-for="comment in discussion.comments.elements"
        :key="comment.id"
        :model-value="comment"
        :current-actor="currentActor"
        @update:modelValue="
          (comment: IComment) =>
            updateComment({
              commentId: comment.id as string,
              text: comment.text,
            })
        "
        @delete-comment="(comment: IComment) => deleteComment({
      commentId: comment.id as string,
    })"
      />
      <o-button
        v-if="discussion.comments.elements.length < discussion.comments.total"
        @click="loadMoreComments"
        >{{ t("Fetch more") }}</o-button
      >
      <form @submit.prevent="reply" v-if="!error">
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
    </section>
  </div>
</template>
<script lang="ts" setup>
import {
  GET_DISCUSSION,
  REPLY_TO_DISCUSSION,
  UPDATE_DISCUSSION,
  DELETE_DISCUSSION,
  DISCUSSION_COMMENT_CHANGED,
} from "@/graphql/discussion";
import { IDiscussion } from "@/types/discussions";
import { displayName, IPerson, usernameWithDomain } from "@/types/actor";
import DiscussionComment from "@/components/Discussion/DiscussionComment.vue";
import { DELETE_COMMENT, UPDATE_COMMENT } from "@/graphql/comment";
import RouteName from "../../router/name";
import { IComment } from "../../types/comment.model";
import { ApolloCache, FetchResult, gql } from "@apollo/client/core";
import { useMutation, useQuery } from "@vue/apollo-composable";
import {
  defineAsyncComponent,
  onMounted,
  onUnmounted,
  ref,
  computed,
  inject,
} from "vue";
import { useHead } from "@vueuse/head";
import { useRouter } from "vue-router";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { AbsintheGraphQLError } from "@/types/errors.model";
import { useGroup } from "@/composition/apollo/group";
import { MemberRole } from "@/types/enums";
import { PERSON_MEMBERSHIPS } from "@/graphql/actor";
import { Dialog } from "@/plugins/dialog";
import { useI18n } from "vue-i18n";

const props = defineProps<{ slug: string }>();

const page = ref(1);
const COMMENTS_PER_PAGE = 10;

const { currentActor } = useCurrentActorClient();

const {
  result: discussionResult,
  onError: onDiscussionError,
  subscribeToMore,
  fetchMore,
  loading: discussionLoading,
} = useQuery<{ discussion: IDiscussion }>(
  GET_DISCUSSION,
  () => ({
    slug: props.slug,
    page: page.value,
    limit: COMMENTS_PER_PAGE,
  }),
  () => ({
    enabled: props.slug !== undefined,
  })
);

subscribeToMore({
  document: DISCUSSION_COMMENT_CHANGED,
  variables: {
    slug: props.slug,
    page: page.value,
    limit: COMMENTS_PER_PAGE,
  },
  updateQuery(
    previousResult: any,
    { subscriptionData }: { subscriptionData: any }
  ) {
    const previousDiscussion = previousResult.discussion;
    const lastComment =
      subscriptionData.data.discussionCommentChanged.lastComment;
    hasMoreComments.value = !previousDiscussion.comments.elements.some(
      (comment: IComment) => comment.id === lastComment.id
    );
    if (hasMoreComments.value) {
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
});

const discussion = computed(() => discussionResult.value?.discussion);

const { group } = useGroup(usernameWithDomain(discussion.value?.actor));

const Editor = defineAsyncComponent(
  () => import("@/components/TextEditor.vue")
);

useHead({
  title: computed(() => discussion.value?.title ?? ""),
});

const newComment = ref("");
const newTitle = ref("");
const editTitleMode = ref(false);
const hasMoreComments = ref(true);
const error = ref<string | null>(null);

const { mutate: replyToDiscussionMutation } = useMutation(REPLY_TO_DISCUSSION);

const reply = () => {
  if (newComment.value === "") return;

  replyToDiscussionMutation({
    discussionId: discussion.value?.id,
    text: newComment.value,
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
      discussion: IDiscussion;
    }>({
      query: GET_DISCUSSION,
      variables: {
        slug: props.slug,
        page: page.value,
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
      variables: { slug: props.slug, page: page.value },
      data: { discussion: discussionCached },
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
  page.value++;
  try {
    await fetchMore({
      // New variables
      variables: {
        slug: props.slug,
        page: page.value,
        limit: COMMENTS_PER_PAGE,
      },
    });
    hasMoreComments.value = !discussion.value?.comments.elements
      .map(({ id }) => id)
      .includes(discussion.value?.lastComment?.id);
  } catch (e) {
    console.error(e);
  }
};

const { mutate: updateDiscussionMutation } = useMutation<{
  updateDiscussion: IDiscussion;
}>(UPDATE_DISCUSSION);

const updateDiscussion = async (): Promise<void> => {
  updateDiscussionMutation({
    discussionId: discussion.value?.id,
    title: newTitle.value,
  });

  editTitleMode.value = false;
};

const { t } = useI18n({ useScope: "global" });
const dialog = inject<Dialog>("dialog");

const openDeleteDiscussionConfirmation = (): void => {
  dialog?.confirm({
    variant: "danger",
    title: t("Delete this discussion"),
    message: t("Are you sure you want to delete this entire discussion?"),
    confirmText: t("Delete discussion"),
    cancelText: t("Cancel"),
    onConfirm: () =>
      deleteConversation({
        discussionId: discussion.value?.id,
      }),
  });
};

const router = useRouter();

const { mutate: deleteConversation, onDone: deleteConversationDone } =
  useMutation(DELETE_DISCUSSION);

deleteConversationDone(() => {
  if (discussion.value?.actor) {
    router.push({
      name: RouteName.DISCUSSION_LIST,
      params: {
        preferredUsername: usernameWithDomain(discussion.value.actor),
      },
    });
  }
});

onDiscussionError((discussionError) =>
  handleErrors(discussionError.graphQLErrors as AbsintheGraphQLError[])
);

const handleErrors = async (errors: AbsintheGraphQLError[]): Promise<void> => {
  if (errors[0].message.includes("No such discussion")) {
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
    loadMoreComments();
  }
};

const isCurrentActorAGroupModerator = computed((): boolean => {
  return hasCurrentActorThisRole([
    MemberRole.MODERATOR,
    MemberRole.ADMINISTRATOR,
  ]);
});

const { result: membershipsResult } = useQuery<{
  person: Pick<IPerson, "memberships">;
}>(
  PERSON_MEMBERSHIPS,
  () => ({ id: currentActor.value?.id }),
  () => ({ enabled: currentActor.value?.id !== undefined })
);
const memberships = computed(() => membershipsResult.value?.person.memberships);

const hasCurrentActorThisRole = (givenRole: string | string[]): boolean => {
  const roles = Array.isArray(givenRole)
    ? givenRole
    : ([givenRole] as MemberRole[]);
  return (
    (memberships.value?.total ?? 0) > 0 &&
    roles.includes(memberships.value?.elements[0].role as MemberRole)
  );
};
</script>
