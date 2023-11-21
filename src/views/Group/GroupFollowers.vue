<template>
  <div>
    <breadcrumbs-nav
      v-if="group"
      :links="[
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
          text: displayName(group),
        },
        {
          name: RouteName.GROUP_SETTINGS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Settings'),
        },
        {
          name: RouteName.GROUP_FOLLOWERS_SETTINGS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Followers'),
        },
      ]"
    />
    <o-loading :active="loading" />
    <section
      class="container mx-auto section"
      v-if="group && isCurrentActorAGroupAdmin && followers"
    >
      <h1>{{ t("Group Followers") }} ({{ followers.total }})</h1>
      <o-field :label="t('Status')" horizontal>
        <o-switch v-model="pending">{{ t("Pending") }}</o-switch>
      </o-field>
      <o-table
        :data="followers.elements"
        ref="queueTable"
        :loading="loading"
        paginated
        backend-pagination
        v-model:current-page="page"
        :pagination-simple="true"
        :aria-next-label="t('Next page')"
        :aria-previous-label="t('Previous page')"
        :aria-page-label="t('Page')"
        :aria-current-label="t('Current page')"
        :total="followers.total"
        :per-page="FOLLOWERS_PER_PAGE"
        backend-sorting
        :default-sort-direction="'desc'"
        :default-sort="['insertedAt', 'desc']"
        @page-change="loadMoreFollowers"
        @sort="(field: any, order: any) => $emit('sort', field, order)"
      >
        <o-table-column
          field="actor.preferredUsername"
          :label="t('Follower')"
          v-slot="props"
        >
          <article class="flex gap-1">
            <figure v-if="props.row.actor.avatar">
              <img
                class="rounded"
                :src="props.row.actor.avatar.url"
                alt=""
                width="48"
                height="48"
              />
            </figure>
            <AccountCircle v-else :size="48" />
            <div class="">
              <div class="">
                <span v-if="props.row.actor.name">{{
                  props.row.actor.name
                }}</span
                ><br />
                <span class="">@{{ usernameWithDomain(props.row.actor) }}</span>
              </div>
            </div>
          </article>
        </o-table-column>
        <o-table-column field="insertedAt" :label="t('Date')" v-slot="props">
          <span class="has-text-centered">
            {{ formatDateString(props.row.insertedAt) }}<br />{{
              formatTimeString(props.row.insertedAt)
            }}
          </span>
        </o-table-column>
        <o-table-column field="actions" :label="t('Actions')" v-slot="props">
          <div class="flex gap-2">
            <o-button
              v-if="!props.row.approved"
              @click="updateFollower(props.row, true)"
              icon-left="check"
              variant="success"
              >{{ t("Accept") }}</o-button
            >
            <o-button
              @click="updateFollower(props.row, false)"
              icon-left="close"
              variant="danger"
              >{{ t("Reject") }}</o-button
            >
          </div>
        </o-table-column>
        <template #empty>
          <empty-content icon="account" inline>
            {{ t("No follower matches the filters") }}
          </empty-content>
        </template>
      </o-table>
    </section>
    <o-notification v-else-if="!loading && group">
      {{ t("You are not an administrator for this group.") }}
    </o-notification>
  </div>
</template>

<script lang="ts" setup>
import { GROUP_FOLLOWERS, UPDATE_FOLLOWER } from "@/graphql/followers";
import RouteName from "../../router/name";
import { displayName, usernameWithDomain } from "../../types/actor";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import { IFollower } from "@/types/actor/follower.model";
import { useMutation, useQuery } from "@vue/apollo-composable";
import {
  booleanTransformer,
  integerTransformer,
  useRouteQuery,
} from "vue-use-route-query";
import { computed, inject } from "vue";
import { useHead } from "@unhead/vue";
import { useI18n } from "vue-i18n";
import { usePersonStatusGroup } from "@/composition/apollo/actor";
import { MemberRole } from "@/types/enums";
import { formatTimeString, formatDateString } from "@/filters/datetime";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import { Notifier } from "@/plugins/notifier";

const props = defineProps<{ preferredUsername: string }>();

const preferredUsername = computed(() => props.preferredUsername);

const page = useRouteQuery("page", 1, integerTransformer);

const pending = useRouteQuery("pending", false, booleanTransformer);

const FOLLOWERS_PER_PAGE = 10;

const {
  result: followersResult,
  fetchMore,
  loading,
} = useQuery(GROUP_FOLLOWERS, () => ({
  name: props.preferredUsername,
  followersPage: page.value,
  followersLimit: FOLLOWERS_PER_PAGE,
  approved: !pending.value,
}));

const group = computed(() => followersResult.value?.group);

const followers = computed(
  () => group.value?.followers ?? { total: 0, elements: [] }
);

const { t } = useI18n({ useScope: "global" });

useHead({ title: computed(() => t("Group Followers")) });

const loadMoreFollowers = async (): Promise<void> => {
  console.debug("load more followers");
  await fetchMore({
    // New variables
    variables: {
      name: usernameWithDomain(group.value),
      followersPage: page.value,
      followersLimit: FOLLOWERS_PER_PAGE,
      approved: !pending.value,
    },
  });
};

const notifier = inject<Notifier>("notifier");

const { onDone, onError, mutate } = useMutation<{ updateFollower: IFollower }>(
  UPDATE_FOLLOWER,
  () => ({
    refetchQueries: [
      {
        query: GROUP_FOLLOWERS,
        variables: {
          name: usernameWithDomain(group.value),
          followersPage: page.value,
          followersLimit: FOLLOWERS_PER_PAGE,
          approved: !pending.value,
        },
      },
    ],
  })
);

onDone(({ data }) => {
  const follower = data?.updateFollower;
  const message =
    data?.updateFollower.approved === true
      ? t("{user}'s follow request was accepted", {
          user: displayName(follower?.actor),
        })
      : t("{user}'s follow request was rejected", {
          user: displayName(follower?.actor),
        });
  notifier?.success(message);
});

onError((error) => {
  console.error(error);
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

const updateFollower = async (
  follower: IFollower,
  approved: boolean
): Promise<void> => {
  mutate({
    id: follower.id,
    approved,
  });
};

const isCurrentActorAGroupAdmin = computed((): boolean => {
  return hasCurrentActorThisRole(MemberRole.ADMINISTRATOR);
});

const hasCurrentActorThisRole = (givenRole: string | string[]): boolean => {
  const roles = Array.isArray(givenRole) ? givenRole : [givenRole];
  return (
    personMemberships.value?.total > 0 &&
    roles.includes(personMemberships.value?.elements[0].role)
  );
};

const personMemberships = computed(
  () => person.value?.memberships ?? { total: 0, elements: [] }
);

const { person } = usePersonStatusGroup(preferredUsername.value);
</script>
