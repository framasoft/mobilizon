<template>
  <div class="container mx-auto" v-if="group">
    <breadcrumbs-nav
      :links="[
        {
          name: RouteName.GROUP,
          params: { preferredUsername: usernameWithDomain(group) },
          text: displayName(group),
        },
        {
          name: RouteName.GROUP_EVENTS,
          params: { preferredUsername: usernameWithDomain(group) },
          text: t('Events'),
        },
      ]"
    />
    <section>
      <h1 class="" v-if="group">
        {{
          t("{group}'s events", {
            group: displayName(group),
          })
        }}
      </h1>
      <p v-if="isCurrentActorMember">
        {{
          t(
            "When a moderator from the group creates an event and attributes it to the group, it will show up here."
          )
        }}
      </p>
      <o-button
        tag="router-link"
        variant="primary"
        v-if="isCurrentActorAGroupModerator"
        :to="{
          name: RouteName.CREATE_EVENT,
          query: { actorId: group.id },
        }"
        >{{ t("+ Create an event") }}</o-button
      >
      <o-loading v-model:active="groupLoading"></o-loading>
      <section v-if="group">
        <h2 class="text-2xl">
          {{ showPassedEvents ? t("Past events") : t("Upcoming events") }}
        </h2>
        <o-switch class="mb-4" v-model="showPassedEvents">{{
          t("Past events")
        }}</o-switch>
        <grouped-multi-event-minimalist-card
          class="mb-6"
          :events="group.organizedEvents.elements"
          :isCurrentActorMember="isCurrentActorMember"
          :order="showPassedEvents ? 'DESC' : 'ASC'"
        />
        <empty-content
          v-if="
            group.organizedEvents.elements.length === 0 &&
            groupLoading === false
          "
          icon="calendar"
          :inline="true"
          :center="true"
        >
          {{ t("No events found") }}
          <template v-if="group.domain !== null">
            <div class="mt-4">
              <p>
                {{
                  t(
                    "This group is a remote group, it's possible the original instance has more informations."
                  )
                }}
              </p>
              <o-button variant="text" tag="a" :href="group.url">
                {{ t("View the group profile on the original instance") }}
              </o-button>
            </div>
          </template>
        </empty-content>
        <o-pagination
          v-if="group.organizedEvents.total > EVENTS_PAGE_LIMIT"
          class="mt-4"
          :total="group.organizedEvents.total"
          v-model:current="page"
          :per-page="EVENTS_PAGE_LIMIT"
          :aria-next-label="t('Next page')"
          :aria-previous-label="t('Previous page')"
          :aria-page-label="t('Page')"
          :aria-current-label="t('Current page')"
        >
        </o-pagination>
      </section>
    </section>
  </div>
</template>
<script lang="ts" setup>
import RouteName from "@/router/name";
import GroupedMultiEventMinimalistCard from "@/components/Event/GroupedMultiEventMinimalistCard.vue";
import { PERSON_MEMBERSHIPS } from "@/graphql/actor";
import { FETCH_GROUP_EVENTS } from "@/graphql/event";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import {
  displayName,
  IGroup,
  IPerson,
  usernameWithDomain,
} from "../../types/actor";
import { useQuery } from "@vue/apollo-composable";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { computed, watch } from "vue";
import { useRoute } from "vue-router";
import {
  booleanTransformer,
  integerTransformer,
  useRouteQuery,
} from "vue-use-route-query";
import { MemberRole } from "@/types/enums";
import { useHead } from "@vueuse/head";
import { useI18n } from "vue-i18n";

const EVENTS_PAGE_LIMIT = 10;

const { currentActor } = useCurrentActorClient();

const { result: membershipsResult } = useQuery<{
  person: Pick<IPerson, "memberships">;
}>(
  PERSON_MEMBERSHIPS,
  () => ({ id: currentActor.value?.id }),
  () => ({
    enabled:
      currentActor.value?.id !== undefined && currentActor.value?.id !== null,
  })
);
const memberships = computed(
  () => membershipsResult.value?.person.memberships?.elements
);

const route = useRoute();
const page = useRouteQuery("page", 1, integerTransformer);
const showPassedEvents = useRouteQuery(
  "showPassedEvents",
  false,
  booleanTransformer
);

/**
 * Why is the following hack needed? Page doesn't want to be reactive!
 * TODO: investigate
 */
const variables = computed(() => ({
  name: route.params.preferredUsername as string,
  beforeDateTime: showPassedEvents.value ? new Date() : null,
  afterDateTime: showPassedEvents.value ? null : new Date(),
  order: "BEGINS_ON",
  orderDirection: showPassedEvents.value ? "DESC" : "ASC",
  organisedEventsPage: page.value,
  organisedEventsLimit: EVENTS_PAGE_LIMIT,
}));

watch(
  variables,
  (newVariables) => {
    refetch(newVariables);
  },
  { deep: true }
);

const {
  result: groupResult,
  loading: groupLoading,
  refetch: refetch,
} = useQuery<
  {
    group: IGroup;
  },
  {
    name: string;
    beforeDateTime: Date | null;
    afterDateTime: Date | null;
    organisedEventsPage: number;
    organisedEventsLimit: number;
  }
>(FETCH_GROUP_EVENTS, variables);
const group = computed(() => groupResult.value?.group);

const { t } = useI18n({ useScope: "global" });
useHead({
  title: () =>
    t("{group} events", {
      group: displayName(group.value),
    }),
});

const isCurrentActorMember = computed((): boolean => {
  if (!group.value || !memberships.value) return false;
  return (memberships.value ?? [])
    .map(({ parent: { id } }) => id)
    .includes(group.value.id);
});

const isCurrentActorAGroupModerator = computed((): boolean => {
  return hasCurrentActorThisRole([
    MemberRole.MODERATOR,
    MemberRole.ADMINISTRATOR,
  ]);
});

const hasCurrentActorThisRole = (givenRole: string | string[]): boolean => {
  const roles = Array.isArray(givenRole) ? givenRole : [givenRole];
  return (
    memberships.value !== undefined &&
    memberships.value?.length > 0 &&
    roles.includes(memberships.value[0].role)
  );
};
</script>
