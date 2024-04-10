<template>
  <div v-if="group" class="section">
    <breadcrumbs-nav
      :links="[
        { name: RouteName.ADMIN, text: t('Admin') },
        {
          name: RouteName.ADMIN_GROUPS,
          text: t('Groups'),
        },
        {
          name: RouteName.PROFILES,
          params: { id: group.id },
          text: displayName(group),
        },
      ]"
    />
    <div>
      <p v-if="group.suspended" class="mx-auto max-w-sm block mb-2">
        <actor-card
          :actor="group"
          :full="true"
          :popover="false"
          :limit="false"
        />
      </p>
      <router-link
        class="mx-auto max-w-sm block mb-2"
        v-else
        :to="{
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
        }"
      >
        <actor-card
          :actor="group"
          :full="true"
          :popover="false"
          :limit="false"
        />
      </router-link>
    </div>
    <table v-if="metadata.length > 0" class="table w-full">
      <tbody>
        <tr v-for="{ key, value, link } in metadata" :key="key">
          <td>{{ key }}</td>
          <td v-if="link">
            <router-link :to="link">
              {{ value }}
            </router-link>
          </td>
          <td v-else>{{ value }}</td>
        </tr>
      </tbody>
    </table>
    <div class="flex gap-1">
      <o-button
        @click="confirmSuspendProfile"
        v-if="!group.suspended"
        variant="primary"
        >{{ t("Suspend") }}</o-button
      >
      <o-button
        @click="
          unsuspendProfile({
            id,
          })
        "
        v-if="group.suspended"
        variant="primary"
        >{{ t("Unsuspend") }}</o-button
      >
      <o-button
        @click="
          refreshProfile({
            actorId: id,
          })
        "
        v-if="group.domain"
        variant="primary"
        outlined
        >{{ t("Refresh profile") }}</o-button
      >
    </div>
    <section>
      <h2>
        {{
          t(
            "{number} members",
            {
              number: group.members.total,
            },
            group.members.total
          )
        }}
      </h2>
      <o-table
        :data="group.members.elements"
        :loading="loading"
        paginated
        backend-pagination
        v-model:current-page="membersPage"
        :aria-next-label="t('Next page')"
        :aria-previous-label="t('Previous page')"
        :aria-page-label="t('Page')"
        :aria-current-label="t('Current page')"
        :total="group.members.total"
        :per-page="MEMBERS_PER_PAGE"
        @page-change="onMembersPageChange"
      >
        <o-table-column
          field="actor.preferredUsername"
          :label="t('Member')"
          v-slot="props"
        >
          <article class="flex gap-1">
            <div class="flex-none">
              <router-link
                class="no-underline"
                :to="{
                  name: RouteName.ADMIN_PROFILE,
                  params: { id: props.row.actor.id },
                }"
              >
                <figure v-if="props.row.actor.avatar">
                  <img
                    class="rounded"
                    :src="props.row.actor.avatar.url"
                    alt=""
                    width="48"
                    height="48"
                  />
                </figure>
                <AccountCircle :size="48" v-else />
              </router-link>
            </div>
            <div>
              <div class="prose dark:prose-invert">
                <router-link
                  class="no-underline"
                  :to="{
                    name: RouteName.ADMIN_PROFILE,
                    params: { id: props.row.actor.id },
                  }"
                  v-if="props.row.actor.name"
                  >{{ props.row.actor.name }}</router-link
                ><router-link
                  class="no-underline"
                  :to="{
                    name: RouteName.ADMIN_PROFILE,
                    params: { id: props.row.actor.id },
                  }"
                  v-else
                  >@{{ usernameWithDomain(props.row.actor) }}</router-link
                ><br />
                <router-link
                  class="no-underline"
                  :to="{
                    name: RouteName.ADMIN_PROFILE,
                    params: { id: props.row.actor.id },
                  }"
                  v-if="props.row.actor.name"
                  >@{{ usernameWithDomain(props.row.actor) }}</router-link
                >
              </div>
            </div>
          </article>
        </o-table-column>
        <o-table-column field="role" :label="t('Role')" v-slot="props">
          <tag
            variant="primary"
            v-if="props.row.role === MemberRole.ADMINISTRATOR"
          >
            {{ t("Administrator") }}
          </tag>
          <tag
            variant="primary"
            v-else-if="props.row.role === MemberRole.MODERATOR"
          >
            {{ t("Moderator") }}
          </tag>
          <tag v-else-if="props.row.role === MemberRole.MEMBER">
            {{ t("Member") }}
          </tag>
          <tag
            variant="warning"
            v-else-if="props.row.role === MemberRole.NOT_APPROVED"
          >
            {{ t("Not approved") }}
          </tag>
          <tag
            variant="danger"
            v-else-if="props.row.role === MemberRole.REJECTED"
          >
            {{ t("Rejected") }}
          </tag>
          <tag
            variant="danger"
            v-else-if="props.row.role === MemberRole.INVITED"
          >
            {{ t("Invited") }}
          </tag>
        </o-table-column>
        <o-table-column field="insertedAt" :label="t('Date')" v-slot="props">
          <span class="has-text-centered">
            {{ formatDateString(props.row.insertedAt) }}<br />{{
              formatTimeString(props.row.insertedAt)
            }}
          </span>
        </o-table-column>
        <template #empty>
          <empty-content icon="account-group" :inline="true">
            {{ t("No members found") }}
          </empty-content>
        </template>
      </o-table>
    </section>
    <section>
      <h2>
        {{
          t(
            "{number} organized events",
            {
              number: group.organizedEvents.total,
            },
            group.organizedEvents.total
          )
        }}
      </h2>
      <o-table
        :data="group.organizedEvents.elements"
        :loading="loading"
        paginated
        backend-pagination
        v-model:current-page="organizedEventsPage"
        :aria-next-label="t('Next page')"
        :aria-previous-label="t('Previous page')"
        :aria-page-label="t('Page')"
        :aria-current-label="t('Current page')"
        :total="group.organizedEvents.total"
        :per-page="EVENTS_PER_PAGE"
        @page-change="onOrganizedEventsPageChange"
      >
        <o-table-column field="title" :label="t('Title')" v-slot="props">
          <router-link
            :to="{ name: RouteName.EVENT, params: { uuid: props.row.uuid } }"
          >
            {{ props.row.title }}
            <tag variant="info" v-if="props.row.draft">{{ t("Draft") }}</tag>
          </router-link>
        </o-table-column>
        <o-table-column field="beginsOn" :label="t('Begins on')" v-slot="props">
          {{ formatDateTimeString(props.row.beginsOn) }}
        </o-table-column>
        <template #empty>
          <empty-content icon="account-group" :inline="true">
            {{ t("No organized events found") }}
          </empty-content>
        </template>
      </o-table>
    </section>
    <section>
      <h2>
        {{
          t(
            "{number} posts",
            {
              number: group.posts.total,
            },
            group.posts.total
          )
        }}
      </h2>
      <o-table
        :data="group.posts.elements"
        :loading="loading"
        paginated
        backend-pagination
        v-model:current-page="postsPage"
        :aria-next-label="t('Next page')"
        :aria-previous-label="t('Previous page')"
        :aria-page-label="t('Page')"
        :aria-current-label="t('Current page')"
        :total="group.posts.total"
        :per-page="POSTS_PER_PAGE"
        @page-change="onPostsPageChange"
      >
        <o-table-column field="title" :label="t('Title')" v-slot="props">
          <router-link
            :to="{ name: RouteName.POST, params: { slug: props.row.slug } }"
          >
            {{ props.row.title }}
            <tag variant="info" v-if="props.row.draft">{{ t("Draft") }}</tag>
          </router-link>
        </o-table-column>
        <o-table-column
          field="publishAt"
          :label="t('Publication date')"
          v-slot="props"
        >
          {{ formatDateTimeString(props.row.publishAt) }}
        </o-table-column>
        <template #empty>
          <empty-content icon="bullhorn" :inline="true">
            {{ t("No posts found") }}
          </empty-content>
        </template>
      </o-table>
    </section>
  </div>
  <empty-content v-else-if="!loading" icon="account-multiple">
    {{ t("This group was not found") }}
    <template #desc>
      <o-button
        variant="text"
        tag="router-link"
        :to="{ name: RouteName.ADMIN_GROUPS }"
        >{{ t("Back to group list") }}</o-button
      >
    </template>
  </empty-content>
</template>
<script lang="ts" setup>
import { GET_GROUP, REFRESH_PROFILE } from "@/graphql/group";
import { formatBytes } from "@/utils/datetime";
import { MemberRole } from "@/types/enums";
import { SUSPEND_PROFILE, UNSUSPEND_PROFILE } from "../../graphql/actor";
import { IGroup } from "../../types/actor";
import {
  usernameWithDomain,
  displayName,
  IActor,
} from "../../types/actor/actor.model";
import RouteName from "../../router/name";
import ActorCard from "../../components/Account/ActorCard.vue";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import { ApolloCache, FetchResult } from "@apollo/client/core";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { computed, inject } from "vue";
import { useHead } from "@/utils/head";
import { integerTransformer, useRouteQuery } from "vue-use-route-query";
import { useI18n } from "vue-i18n";
import {
  formatTimeString,
  formatDateString,
  formatDateTimeString,
} from "@/filters/datetime";
import { Dialog } from "@/plugins/dialog";
import { Notifier } from "@/plugins/notifier";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import Tag from "@/components/TagElement.vue";

const EVENTS_PER_PAGE = 10;
const POSTS_PER_PAGE = 10;
const MEMBERS_PER_PAGE = 10;

const props = defineProps<{ id: string }>();

const organizedEventsPage = useRouteQuery(
  "organizedEventsPage",
  1,
  integerTransformer
);
const membersPage = useRouteQuery("membersPage", 1, integerTransformer);
const postsPage = useRouteQuery("postsPage", 1, integerTransformer);

const {
  result: groupResult,
  loading,
  fetchMore,
} = useQuery(
  GET_GROUP,
  () => ({
    id: props.id,
    organizedEventsPage: organizedEventsPage.value,
    organizedEventsLimit: EVENTS_PER_PAGE,
    postsPage: postsPage.value,
    postsLimit: POSTS_PER_PAGE,
    membersLimit: MEMBERS_PER_PAGE,
    membersPage: membersPage.value,
  }),
  () => ({
    enabled: props.id !== undefined,
  })
);

const group = computed(() => groupResult.value?.getGroup);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => displayName(group.value)),
});

const metadata = computed((): Array<Record<string, string>> => {
  if (!group.value) return [];
  const res: Record<string, string>[] = [
    {
      key: t("Status") as string,
      value: (group.value.suspended ? t("Suspended") : t("Active")) as string,
    },
    {
      key: t("Domain") as string,
      value: (group.value.domain ? group.value.domain : t("Local")) as string,
    },
    {
      key: t("Uploaded media size") as string,
      value: formatBytes(group.value.mediaSize),
    },
  ];
  return res;
});

const dialog = inject<Dialog>("dialog");
const notifier = inject<Notifier>("notifier");

const confirmSuspendProfile = (): void => {
  const message = group.value.domain
    ? t(
        "Are you sure you want to <b>suspend</b> this group? As this group originates from instance {instance}, this will only remove local members and delete the local data, as well as rejecting all the future data.",
        { instance: group.value.domain }
      )
    : t(
        "Are you sure you want to <b>suspend</b> this group? All members - including remote ones - will be notified and removed from the group, and <b>all of the group data (events, posts, discussions, todos…) will be irretrievably destroyed</b>."
      );

  dialog?.confirm({
    title: t("Suspend group"),
    message,
    confirmText: t("Suspend group"),
    cancelText: t("Cancel"),
    variant: "danger",
    hasIcon: true,
    onConfirm: () =>
      suspendProfile({
        id: props.id,
      }),
  });
};

const { mutate: suspendProfile, onError: onSuspendProfileError } = useMutation<{
  suspendProfile: { id: string };
}>(SUSPEND_PROFILE, () => ({
  update: (
    store: ApolloCache<{ suspendProfile: { id: string } }>,
    { data }: FetchResult
  ) => {
    if (data == null) return;
    const profileId = props.id;

    const profileData = store.readQuery<{ getGroup: IGroup }>({
      query: GET_GROUP,
      variables: {
        id: profileId,
        organizedEventsPage: organizedEventsPage.value,
        organizedEventsLimit: EVENTS_PER_PAGE,
        postsPage: postsPage.value,
        postsLimit: POSTS_PER_PAGE,
      },
    });

    if (!profileData) return;
    store.writeQuery({
      query: GET_GROUP,
      variables: {
        id: profileId,
      },
      data: {
        getGroup: {
          ...profileData.getGroup,
          suspended: true,
          avatar: null,
          name: "",
          summary: "",
        },
      },
    });
  },
}));

onSuspendProfileError((e) => {
  console.error(e);
  notifier?.error(t("Error while suspending group"));
});

const { mutate: unsuspendProfile, onError: onUnsuspendProfileError } =
  useMutation(UNSUSPEND_PROFILE, () => ({
    refetchQueries: [
      {
        query: GET_GROUP,
        variables: {
          id: props.id,
        },
      },
    ],
  }));

onUnsuspendProfileError((e) => {
  console.error(e);
  notifier?.error(t("Error while suspending group"));
});

const {
  mutate: refreshProfile,
  onDone: onRefreshProfileDone,
  onError: onRefreshProfileError,
} = useMutation<{ refreshProfile: IActor }>(REFRESH_PROFILE);

onRefreshProfileDone(() => {
  notifier?.success(t("Triggered profile refreshment"));
});

onRefreshProfileError((e) => {
  console.error(e);
  notifier?.error(t("Error while suspending group"));
});

const onOrganizedEventsPageChange = async (page: number): Promise<void> => {
  organizedEventsPage.value = page;
  await fetchMore({
    variables: {
      id: props.id,
      organizedEventsPage: organizedEventsPage.value,
      organizedEventsLimit: EVENTS_PER_PAGE,
    },
  });
};

const onMembersPageChange = async (page: number): Promise<void> => {
  membersPage.value = page;
  await fetchMore({
    variables: {
      id: props.id,
      membersPage: membersPage.value,
      membersLimit: EVENTS_PER_PAGE,
    },
  });
};

const onPostsPageChange = async (page: number): Promise<void> => {
  postsPage.value = page;
  await fetchMore({
    variables: {
      id: props.id,
      postsPage: postsPage.value,
      postsLimit: POSTS_PER_PAGE,
    },
  });
};
</script>
