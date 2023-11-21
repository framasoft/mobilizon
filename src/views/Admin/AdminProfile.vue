<template>
  <div v-if="person" class="section">
    <breadcrumbs-nav
      :links="[
        { name: RouteName.ADMIN, text: $t('Admin') },
        {
          name: RouteName.PROFILES,
          text: $t('Profiles'),
        },
        {
          name: RouteName.PROFILES,
          params: { id: person.id },
          text: displayName(person),
        },
      ]"
    />

    <div class="flex justify-center">
      <actor-card
        :actor="person"
        :full="true"
        :popover="false"
        :limit="false"
      />
    </div>
    <section class="mt-4 mb-3">
      <h2 class="">{{ $t("Details") }}</h2>
      <div class="flex flex-col">
        <div class="overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block py-2 min-w-full sm:px-2 lg:px-8">
            <div class="overflow-hidden shadow-md sm:rounded-lg">
              <table v-if="metadata.length > 0" class="min-w-full">
                <tbody>
                  <tr
                    v-for="{ key, value, link } in metadata"
                    :key="key"
                    class="odd:bg-white dark:odd:bg-zinc-800 even:bg-gray-50 dark:even:bg-zinc-700 border-b"
                  >
                    <td class="py-4 px-2 whitespace-nowrap">
                      {{ key }}
                    </td>
                    <td
                      v-if="link"
                      class="py-4 px-2 text-sm text-gray-500 dark:text-gray-200 whitespace-nowrap"
                    >
                      <router-link :to="link">
                        {{ value }}
                      </router-link>
                    </td>
                    <td
                      v-else
                      class="py-4 px-2 text-sm text-gray-500 dark:text-gray-200 whitespace-nowrap"
                    >
                      {{ value }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </section>
    <section class="mt-4 mb-3">
      <h2 class="">{{ $t("Actions") }}</h2>
      <div class="buttons" v-if="person.domain">
        <o-button
          @click="suspendProfile({ id })"
          v-if="person.domain && !person.suspended"
          variant="primary"
          >{{ $t("Suspend") }}</o-button
        >
        <o-button
          @click="unsuspendProfile({ id })"
          v-if="person.domain && person.suspended"
          variant="primary"
          >{{ $t("Unsuspend") }}</o-button
        >
      </div>
      <p v-else></p>
      <div
        v-if="person.user"
        class="p-4 mb-4 text-sm text-blue-700 bg-blue-100 rounded-lg"
        role="alert"
      >
        <i18n-t
          keypath="This profile is located on this instance, so you need to {access_the_corresponding_account} to suspend it."
        >
          <template #access_the_corresponding_account>
            <router-link
              class="underline"
              :to="{
                name: RouteName.ADMIN_USER_PROFILE,
                params: { id: person.user.id },
              }"
              >{{ $t("access the corresponding account") }}</router-link
            >
          </template>
        </i18n-t>
      </div>
    </section>
    <section class="mt-4 mb-3">
      <h2 class="">{{ $t("Organized events") }}</h2>
      <o-table
        :data="person.organizedEvents?.elements"
        :loading="loading"
        paginated
        backend-pagination
        v-model:current-page="organizedEventsPage"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
        :total="person.organizedEvents?.total"
        :per-page="EVENTS_PER_PAGE"
        @page-change="onOrganizedEventsPageChange"
      >
        <o-table-column
          field="beginsOn"
          :label="$t('Begins on')"
          v-slot="props"
        >
          {{ formatDateTimeString(props.row.beginsOn) }}
        </o-table-column>
        <o-table-column field="title" :label="$t('Title')" v-slot="props">
          <router-link
            :to="{ name: RouteName.EVENT, params: { uuid: props.row.uuid } }"
          >
            {{ props.row.title }}
          </router-link>
        </o-table-column>
        <template #empty>
          <empty-content icon="account-group" :inline="true">
            {{ $t("No organized events listed") }}
          </empty-content>
        </template>
      </o-table>
    </section>
    <section class="mt-4 mb-3">
      <h2 class="">{{ $t("Participations") }}</h2>
      <o-table
        :data="
          person.participations?.elements.map(
            (participation) => participation.event
          )
        "
        :loading="loading"
        paginated
        backend-pagination
        v-model:current-page="participationsPage"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
        :total="person.participations?.total"
        :per-page="EVENTS_PER_PAGE"
        @page-change="onParticipationsPageChange"
      >
        <o-table-column
          field="beginsOn"
          :label="$t('Begins on')"
          v-slot="props"
        >
          {{ formatDateTimeString(props.row.beginsOn) }}
        </o-table-column>
        <o-table-column field="title" :label="$t('Title')" v-slot="props">
          <router-link
            :to="{ name: RouteName.EVENT, params: { uuid: props.row.uuid } }"
          >
            {{ props.row.title }}
          </router-link>
        </o-table-column>
        <template #empty>
          <empty-content icon="account-group" :inline="true">
            {{ $t("No participations listed") }}
          </empty-content>
        </template>
      </o-table>
    </section>
    <section class="mt-4 mb-3">
      <h2 class="">{{ $t("Memberships") }}</h2>
      <o-table
        :data="person.memberships?.elements"
        :loading="loading"
        paginated
        backend-pagination
        v-model:current-page="membershipsPage"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
        :total="person.memberships?.total"
        :per-page="EVENTS_PER_PAGE"
        @page-change="onMembershipsPageChange"
      >
        <o-table-column
          field="parent.preferredUsername"
          :label="$t('Group')"
          v-slot="props"
        >
          <article class="flex gap-2">
            <router-link
              class="no-underline"
              :to="{
                name: RouteName.ADMIN_GROUP_PROFILE,
                params: { id: props.row.parent.id },
              }"
            >
              <figure class="" v-if="props.row.parent.avatar">
                <img
                  class="rounded-full"
                  :src="props.row.parent.avatar.url"
                  alt=""
                  width="48"
                  height="48"
                />
              </figure>
              <AccountCircle v-else :size="48" />
            </router-link>
            <div class="">
              <div class="prose dark:prose-invert">
                <router-link
                  class="no-underline"
                  :to="{
                    name: RouteName.ADMIN_GROUP_PROFILE,
                    params: { id: props.row.parent.id },
                  }"
                  v-if="props.row.parent.name"
                  >{{ props.row.parent.name }}</router-link
                ><br />
                <router-link
                  class="no-underline"
                  :to="{
                    name: RouteName.ADMIN_GROUP_PROFILE,
                    params: { id: props.row.parent.id },
                  }"
                  >@{{ usernameWithDomain(props.row.parent) }}</router-link
                >
              </div>
            </div>
          </article>
        </o-table-column>
        <o-table-column field="role" :label="$t('Role')" v-slot="props">
          <tag
            variant="primary"
            v-if="props.row.role === MemberRole.ADMINISTRATOR"
          >
            {{ $t("Administrator") }}
          </tag>
          <tag
            variant="primary"
            v-else-if="props.row.role === MemberRole.MODERATOR"
          >
            {{ $t("Moderator") }}
          </tag>
          <tag v-else-if="props.row.role === MemberRole.MEMBER">
            {{ $t("Member") }}
          </tag>
          <tag
            variant="warning"
            v-else-if="props.row.role === MemberRole.NOT_APPROVED"
          >
            {{ $t("Not approved") }}
          </tag>
          <tag
            variant="danger"
            v-else-if="props.row.role === MemberRole.REJECTED"
          >
            {{ $t("Rejected") }}
          </tag>
          <tag
            variant="danger"
            v-else-if="props.row.role === MemberRole.INVITED"
          >
            {{ $t("Invited") }}
          </tag>
        </o-table-column>
        <o-table-column field="insertedAt" :label="$t('Date')" v-slot="props">
          <span class="has-text-centered">
            {{ formatDateString(props.row.insertedAt) }}<br />{{
              formatTimeString(props.row.insertedAt)
            }}
          </span>
        </o-table-column>
        <template #empty>
          <empty-content icon="account-group" :inline="true">
            {{ $t("No memberships found") }}
          </empty-content>
        </template>
      </o-table>
    </section>
  </div>
  <empty-content v-else-if="!loading" icon="account">
    {{ $t("This profile was not found") }}
    <template #desc>
      <o-button
        variant="text"
        tag="router-link"
        :to="{ name: RouteName.PROFILES }"
        >{{ $t("Back to profile list") }}</o-button
      >
    </template>
  </empty-content>
</template>
<script lang="ts" setup>
import { formatBytes } from "@/utils/datetime";
import {
  GET_PERSON,
  SUSPEND_PROFILE,
  UNSUSPEND_PROFILE,
} from "@/graphql/actor";
import { IPerson } from "@/types/actor";
import { displayName, usernameWithDomain } from "@/types/actor/actor.model";
import RouteName from "@/router/name";
import ActorCard from "@/components/Account/ActorCard.vue";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import { ApolloCache, FetchResult } from "@apollo/client/core";
import { MemberRole } from "@/types/enums";
import cloneDeep from "lodash/cloneDeep";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { integerTransformer, useRouteQuery } from "vue-use-route-query";
import { useHead } from "@unhead/vue";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import {
  formatDateString,
  formatTimeString,
  formatDateTimeString,
} from "@/filters/datetime";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import Tag from "@/components/TagElement.vue";

const EVENTS_PER_PAGE = 10;
const PARTICIPATIONS_PER_PAGE = 10;
const MEMBERSHIPS_PER_PAGE = 10;

const props = defineProps<{ id: string }>();

const organizedEventsPage = useRouteQuery(
  "organizedEventsPage",
  1,
  integerTransformer
);
const participationsPage = useRouteQuery(
  "participationsPage",
  1,
  integerTransformer
);
const membershipsPage = useRouteQuery("membershipsPage", 1, integerTransformer);

const {
  result: personResult,
  fetchMore,
  loading,
} = useQuery<{ person: IPerson }>(GET_PERSON, () => ({
  actorId: props.id,
  organizedEventsPage: organizedEventsPage.value,
  organizedEventsLimit: EVENTS_PER_PAGE,
  participationsPage: participationsPage.value,
  participationLimit: PARTICIPATIONS_PER_PAGE,
  membershipsPage: membershipsPage.value,
  membershipsLimit: MEMBERSHIPS_PER_PAGE,
}));

const person = computed(() => personResult.value?.person);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => displayName(person.value)),
});

const metadata = computed(
  (): Array<{
    key: string;
    value: string;
    link?: { name: string; params: Record<string, any> };
  }> => {
    if (!person.value) return [];
    const res: {
      key: string;
      value: string;
      link?: { name: string; params: Record<string, any> };
    }[] = [
      {
        key: t("Status"),
        value: person.value.suspended ? t("Suspended") : t("Active"),
      },
      {
        key: t("Domain"),
        value: person.value.domain ? person.value.domain : t("Local"),
        link: person.value.domain
          ? {
              name: RouteName.INSTANCE,
              params: { domain: person.value.domain },
            }
          : undefined,
      },
      {
        key: t("Uploaded media size"),
        value: formatBytes(person.value.mediaSize ?? 0),
      },
    ];
    if (!person.value.domain && person.value.user) {
      res.push({
        key: t("User"),
        link: {
          name: RouteName.ADMIN_USER_PROFILE,
          params: { id: person.value.user.id },
        },
        value: person.value.user.email,
      });
    }
    return res;
  }
);

const { mutate: suspendProfile } = useMutation<
  {
    suspendProfile: { id: string };
  },
  { id: string }
>(SUSPEND_PROFILE, () => ({
  update: (
    store: ApolloCache<{ suspendProfile: { id: string } }>,
    { data }: FetchResult
  ) => {
    if (data == null) return;
    const profileId = props.id;

    const profileData = store.readQuery<{ person: IPerson }>({
      query: GET_PERSON,
      variables: {
        actorId: profileId,
        organizedEventsPage: 1,
        organizedEventsLimit: EVENTS_PER_PAGE,
        participationsPage: 1,
        participationLimit: PARTICIPATIONS_PER_PAGE,
        membershipsPage: 1,
        membershipsLimit: MEMBERSHIPS_PER_PAGE,
      },
    });

    if (!profileData) return;
    const { person: cachedPerson } = profileData;
    store.writeQuery({
      query: GET_PERSON,
      variables: {
        actorId: profileId,
      },
      data: {
        person: {
          ...cloneDeep(cachedPerson),
          participations: { total: 0, elements: [] },
          suspended: true,
          avatar: null,
          name: "",
          summary: "",
        },
      },
    });
  },
}));

const { mutate: unsuspendProfile } = useMutation<
  { unsuspendProfile: { id: string } },
  { id: string }
>(UNSUSPEND_PROFILE, () => ({
  refetchQueries: [
    {
      query: GET_PERSON,
      variables: {
        actorId: props.id,
        organizedEventsPage: 1,
        organizedEventsLimit: EVENTS_PER_PAGE,
      },
    },
  ],
}));

const onOrganizedEventsPageChange = async (): Promise<void> => {
  await fetchMore({
    variables: {
      actorId: props.id,
      organizedEventsPage: organizedEventsPage.value,
      organizedEventsLimit: EVENTS_PER_PAGE,
    },
  });
};

const onParticipationsPageChange = async (): Promise<void> => {
  await fetchMore({
    variables: {
      actorId: props.id,
      participationPage: participationsPage.value,
      participationLimit: PARTICIPATIONS_PER_PAGE,
    },
  });
};

const onMembershipsPageChange = async (): Promise<void> => {
  await fetchMore({
    variables: {
      actorId: props.id,
      membershipsPage: participationsPage.value,
      membershipsLimit: MEMBERSHIPS_PER_PAGE,
    },
  });
};
</script>
