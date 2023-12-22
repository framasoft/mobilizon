<template>
  <article class="container mx-auto post" v-if="post">
    <breadcrumbs-nav
      v-if="post.attributedTo"
      :links="[
        { name: RouteName.MY_GROUPS, text: t('My groups') },
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(post.attributedTo) },
          text: displayName(post.attributedTo),
        },
        {
          name: RouteName.POST,
          params: { slug: post.slug },
          text: post.title,
        },
      ]"
    />
    <header>
      <div class="flex justify-center">
        <lazy-image-wrapper :picture="post.picture" />
      </div>
      <div class="relative flex flex-col">
        <div
          class="px-2 py-3 flex flex-wrap gap-4 justify-center items-center"
          dir="auto"
        >
          <div class="flex-auto min-w-[300px] max-w-screen-lg">
            <div class="inline">
              <tag
                class="mr-2"
                variant="warning"
                size="medium"
                v-if="post.draft"
                >{{ t("Draft") }}</tag
              >
              <h1 class="inline" :lang="post.language">
                {{ post.title }}
              </h1>
            </div>
            <p class="mt-2 flex flex-col flex-wrap justify-start">
              <router-link
                :to="{
                  name: RouteName.GROUP,
                  params: {
                    preferredUsername: usernameWithDomain(post.attributedTo),
                  },
                }"
              >
                <actor-inline
                  v-if="post.attributedTo"
                  :actor="post.attributedTo"
                />
              </router-link>
              <span
                class="inline-flex gap-2 items-center mt-2"
                v-if="!post.draft && post.publishAt"
              >
                <Clock :size="16" />
                {{ formatDateTimeString(post.publishAt) }}
              </span>
              <span
                class="inline-flex gap-2 items-center mt-2"
                :title="
                  formatDateTimeString(post.updatedAt, undefined, true, 'short')
                "
                v-else-if="post.updatedAt"
              >
                <Clock :size="16" />
                {{
                  t("Edited {relative_time} ago", {
                    relative_time: formatDistanceToNowStrict(
                      new Date(post.updatedAt),
                      {
                        locale: dateFnsLocale,
                      }
                    ),
                  })
                }}
              </span>
              <span
                v-if="post.visibility === PostVisibility.UNLISTED"
                class="flex gap-2 items-center"
              >
                <Link :size="16" />
                {{ t("Accessible only by link") }}
              </span>
              <span
                v-else-if="post.visibility === PostVisibility.PRIVATE"
                class="flex gap-2 items-center"
              >
                <Lock :size="16" />
                {{
                  t("Accessible only to members", {
                    group: post.attributedTo?.name,
                  })
                }}
              </span>
            </p>
          </div>
          <o-dropdown position="bottom-left" aria-role="list">
            <template #trigger>
              <o-button icon-right="dots-horizontal">
                {{ t("Actions") }}
              </o-button>
            </template>
            <o-dropdown-item
              aria-role="listitem"
              has-link
              tabIndex="-1"
              v-if="
                currentActor?.id === post?.author?.id ||
                isCurrentActorAGroupModerator
              "
            >
              <router-link
                class="flex gap-1 whitespace-nowrap flex-1"
                :to="{
                  name: RouteName.POST_EDIT,
                  params: { slug: post.slug },
                }"
              >
                <Pencil />
                {{ t("Edit") }}
              </router-link>
            </o-dropdown-item>
            <o-dropdown-item
              aria-role="listitem"
              v-if="
                currentActor?.id === post?.author?.id ||
                isCurrentActorAGroupModerator
              "
              tabIndex="-1"
            >
              <button
                @click="openDeletePostModal"
                class="flex gap-1 whitespace-nowrap"
              >
                <Delete />
                {{ t("Delete") }}
              </button>
            </o-dropdown-item>

            <hr
              role="presentation"
              class="dropdown-divider"
              aria-role="menuitem"
              v-if="
                currentActor?.id === post?.author?.id ||
                isCurrentActorAGroupModerator
              "
            />
            <o-dropdown-item
              aria-role="listitem"
              v-if="!post.draft"
              tabIndex="-1"
            >
              <button
                @click="triggerShare()"
                class="flex gap-1 whitespace-nowrap"
              >
                <Share />
                {{ t("Share this event") }}
              </button>
            </o-dropdown-item>

            <o-dropdown-item
              aria-role="listitem"
              v-if="ableToReport"
              tabIndex="-1"
            >
              <button
                @click="isReportModalActive = true"
                class="flex gap-1 whitespace-nowrap"
              >
                <Flag />
                {{ t("Report") }}
              </button>
            </o-dropdown-item>
          </o-dropdown>
        </div>
      </div>
    </header>
    <o-notification
      :title="t('Members-only post')"
      class="mx-4"
      variant="warning"
      :closable="false"
      v-if="
        !membershipsLoading &&
        !postLoading &&
        isInstanceModerator &&
        !isCurrentActorAGroupMember &&
        post.visibility === PostVisibility.PRIVATE
      "
    >
      {{
        t(
          "This post is accessible only for members. You have access to it for moderation purposes only because you are an instance moderator."
        )
      }}
    </o-notification>

    <section
      v-html="post.body"
      dir="auto"
      class="px-2 md:px-4 py-4 prose lg:prose-xl prose-p:mt-6 dark:prose-invert bg-white dark:bg-zinc-700 mx-auto"
      :lang="post.language"
    />
    <section class="flex gap-2 my-6 justify-center" dir="auto">
      <router-link
        v-for="tag in post.tags"
        :key="tag.title"
        :to="{ name: RouteName.TAG, params: { tag: tag.title } }"
      >
        <tag>{{ tag.title }}</tag>
      </router-link>
    </section>
    <o-modal
      :close-button-aria-label="t('Close')"
      v-model:active="isReportModalActive"
      has-modal-card
      ref="reportModal"
      :autoFocus="false"
      :trapFocus="false"
    >
      <ReportModal
        :on-confirm="reportPost"
        :title="t('Report this post')"
        :outside-domain="groupDomain"
        @close="isReportModalActive = false"
      />
    </o-modal>
    <o-modal
      v-model:active="isShareModalActive"
      has-modal-card
      ref="shareModal"
      :close-button-aria-label="t('Close')"
    >
      <share-post-modal :post="post" />
    </o-modal>
  </article>
</template>

<script lang="ts" setup>
import { ICurrentUserRole, MemberRole, PostVisibility } from "@/types/enums";
import { PERSON_MEMBERSHIPS } from "@/graphql/actor";
import {
  IGroup,
  IPerson,
  usernameWithDomain,
  displayName,
} from "@/types/actor";
import RouteName from "@/router/name";
import Tag from "@/components/TagElement.vue";
import LazyImageWrapper from "@/components/Image/LazyImageWrapper.vue";
import ActorInline from "@/components/Account/ActorInline.vue";
import { formatDistanceToNowStrict, Locale } from "date-fns";
import SharePostModal from "@/components/Post/SharePostModal.vue";
import ReportModal from "@/components/Report/ReportModal.vue";
import { useAnonymousReportsConfig } from "@/composition/apollo/config";
import {
  useCurrentActorClient,
  usePersonStatusGroup,
} from "@/composition/apollo/actor";
import { useCurrentUserClient } from "@/composition/apollo/user";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { computed, inject, ref } from "vue";
import { IPost } from "@/types/post.model";
import { DELETE_POST, FETCH_POST } from "@/graphql/post";
import { useHead } from "@unhead/vue";
import { formatDateTimeString } from "@/filters/datetime";
import { useRouter } from "vue-router";
import { useCreateReport } from "@/composition/apollo/report";
import Clock from "vue-material-design-icons/Clock.vue";
import Lock from "vue-material-design-icons/Lock.vue";
import Pencil from "vue-material-design-icons/Pencil.vue";
import Delete from "vue-material-design-icons/Delete.vue";
import Share from "vue-material-design-icons/Share.vue";
import Flag from "vue-material-design-icons/Flag.vue";
import Link from "vue-material-design-icons/Link.vue";
import { Dialog } from "@/plugins/dialog";
import { useI18n } from "vue-i18n";
import { Notifier } from "@/plugins/notifier";
import { AbsintheGraphQLErrors } from "@/types/errors.model";

const props = defineProps<{
  slug: string;
}>();

const { anonymousReportsConfig } = useAnonymousReportsConfig();
const { currentUser } = useCurrentUserClient();
const { currentActor } = useCurrentActorClient();

const { result: membershipsResult, loading: membershipsLoading } = useQuery<{
  person: Pick<IPerson, "memberships">;
}>(
  PERSON_MEMBERSHIPS,
  () => ({ id: currentActor.value?.id }),
  () => ({
    enabled:
      currentActor.value?.id !== undefined && currentActor.value?.id !== null,
  })
);
const memberships = computed(() => membershipsResult.value?.person.memberships);

const {
  result: postResult,
  loading: postLoading,
  onError: onFetchPostError,
} = useQuery<{
  post: IPost;
}>(FETCH_POST, () => ({ slug: props.slug }));

const handleErrors = (errors: AbsintheGraphQLErrors): void => {
  if (
    errors.some((error) => error.status_code === 404) ||
    errors.some(({ message }) => message.includes("has invalid value $uuid"))
  ) {
    router.replace({ name: RouteName.PAGE_NOT_FOUND });
  }
};

onFetchPostError(({ graphQLErrors }) =>
  handleErrors(graphQLErrors as AbsintheGraphQLErrors)
);

const post = computed(() => postResult.value?.post);

usePersonStatusGroup(usernameWithDomain(post.value?.attributedTo as IGroup));

useHead({
  title: computed(
    () => `${post.value?.title} - ${displayName(post.value?.attributedTo)}`
  ),
});

const notifier = inject<Notifier>("notifier");

const isShareModalActive = ref(false);
const isReportModalActive = ref(false);
const reportModal = ref();

const isInstanceModerator = computed((): boolean => {
  return (
    currentUser.value?.role !== undefined &&
    [ICurrentUserRole.ADMINISTRATOR, ICurrentUserRole.MODERATOR].includes(
      currentUser.value?.role
    )
  );
});

const ableToReport = computed((): boolean => {
  return (
    currentActor.value?.id != undefined ||
    anonymousReportsConfig.value?.allowed === true
  );
});

const triggerShare = (): void => {
  if (navigator.share) {
    navigator
      .share({
        title: post.value?.title,
        url: post.value?.url,
      })
      .then(() => console.debug("Successful share"))
      .catch((error: any) => console.debug("Error sharing", error));
  } else {
    isShareModalActive.value = true;
    // send popup
  }
};

const {
  mutate: createReportMutation,
  onDone: onCreateReportDone,
  onError: onCreateReportError,
} = useCreateReport();

onCreateReportDone(() => {
  isReportModalActive.value = false;
  reportModal.value.close();
  const postTitle = post.value?.title;
  notifier?.success(t("Post {eventTitle} reported", { postTitle }));
});

onCreateReportError((error) => {
  console.error(error);
});

const reportPost = async (content: string, forward: boolean): Promise<void> => {
  createReportMutation({
    // postId: post.value?.id,
    reportedId: post.value?.attributedTo?.id as string,
    content,
    forward,
  });
};
const groupDomain = computed((): string | undefined | null => {
  return post.value?.attributedTo?.domain;
});

const dateFnsLocale = inject<Locale>("dateFnsLocale");

const isCurrentActorAGroupModerator = computed((): boolean => {
  return hasCurrentActorThisRole([
    MemberRole.MODERATOR,
    MemberRole.ADMINISTRATOR,
  ]);
});

const hasCurrentActorThisRole = (givenRole: string | string[]): boolean => {
  const roles = Array.isArray(givenRole)
    ? givenRole
    : ([givenRole] as MemberRole[]);
  return (
    (memberships.value?.total ?? 0) > 0 &&
    roles.includes(memberships.value?.elements[0].role as MemberRole)
  );
};

const isCurrentActorAGroupMember = computed((): boolean => {
  return hasCurrentActorThisRole([
    MemberRole.MODERATOR,
    MemberRole.ADMINISTRATOR,
    MemberRole.MEMBER,
  ]);
});

const { t } = useI18n({ useScope: "global" });
const dialog = inject<Dialog>("dialog");

const openDeletePostModal = async (): Promise<void> => {
  dialog?.confirm({
    variant: "danger",
    title: t("Delete post"),
    message: t(
      "Are you sure you want to delete this post? This action cannot be reverted."
    ),
    onConfirm: () =>
      deletePost({
        id: post.value?.id,
      }),
  });
};

const router = useRouter();

const { mutate: deletePost, onDone: onDeletePostDone } =
  useMutation(DELETE_POST);

onDeletePostDone(({ data }) => {
  if (data && post.value?.attributedTo) {
    router.push({
      name: RouteName.POSTS,
      params: {
        preferredUsername: usernameWithDomain(post.value?.attributedTo),
      },
    });
  }
});
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
article.post {
  header {
    display: flex;
    flex-direction: column;
    .banner-container {
      display: flex;
      justify-content: center;
      height: 30vh;
    }

    .heading-section {
      position: relative;
      display: flex;
      flex-direction: column;
      margin-bottom: 2rem;

      .heading-wrapper {
        padding: 15px 10px;
        display: flex;
        flex-wrap: wrap;
        justify-content: center;
        align-items: center;

        .title-metadata {
          min-width: 300px;
          flex: 20;

          .title-wrapper {
            display: inline;

            .tag {
              height: 38px;
              vertical-align: text-bottom;
            }

            & > h1 {
              display: inline;
            }
          }

          p.metadata {
            margin-top: 10px;
            display: flex;
            justify-content: flex-start;
            flex-wrap: wrap;
            flex-direction: column;

            *:not(:first-child) {
              @include padding-left(5px);
            }
          }
        }
        p.buttons {
          flex: 1;
        }
      }

      h1.title {
        margin: 0;
        font-weight: 500;
        font-family: "Roboto", "Helvetica", "Arial", serif;
      }

      .authors {
        display: inline-block;
      }

      &::after {
        height: 0.2rem;
        content: " ";
        display: block;
      }

      .buttons {
        justify-content: center;
      }
    }
  }

  margin: 0 auto;
}
</style>
