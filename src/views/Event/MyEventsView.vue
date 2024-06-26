<template>
  <div class="container mx-auto px-1 mb-6">
    <h1>
      {{ t("My events") }}
    </h1>
    <p>
      {{
        t(
          "You will find here all the events you have created or of which you are a participant, as well as events organized by groups you follow or are a member of."
        )
      }}
    </p>
    <div class="my-2" v-if="!hideCreateEventButton">
      <o-button
        tag="router-link"
        variant="primary"
        :to="{ name: RouteName.CREATE_EVENT }"
        >{{ t("Create event") }}</o-button
      >
    </div>
    <!-- <o-loading v-model:active="$apollo.loading"></o-loading> -->
    <div class="flex flex-wrap gap-4 items-start">
      <div
        class="rounded p-3 flex-auto md:flex-none bg-zinc-300 dark:bg-zinc-700"
      >
        <o-field
          class="date-filter"
          expanded
          :label="
            showUpcoming
              ? t('Showing events starting on')
              : t('Showing events before')
          "
          labelFor="events-start-datepicker"
        >
          <o-datepicker
            v-model="datePick"
            :first-day-of-week="firstDayOfWeek"
            id="events-start-datepicker"
          />
          <o-button
            @click="datePick = new Date()"
            class="reset-area !h-auto"
            icon-left="close"
            :title="t('Clear date filter field')"
          />
        </o-field>
        <o-field v-if="showUpcoming">
          <o-checkbox v-model="showDrafts">{{ t("Drafts") }}</o-checkbox>
        </o-field>
        <o-field v-if="showUpcoming">
          <o-checkbox v-model="showAttending">{{ t("Attending") }}</o-checkbox>
        </o-field>
        <o-field v-if="showUpcoming">
          <o-checkbox v-model="showMyGroups">{{
            t("From my groups")
          }}</o-checkbox>
        </o-field>
        <p v-if="!showUpcoming">
          {{
            t(
              "You have attended {count} events in the past.",
              {
                count: pastParticipations.total,
              },
              pastParticipations.total
            )
          }}
        </p>
      </div>
      <div class="flex-1 min-w-[300px]">
        <section
          class="py-4 first:pt-0"
          v-if="showUpcoming && showDrafts && drafts && drafts.total > 0"
        >
          <h2 class="text-2xl mb-2">{{ t("Drafts") }}</h2>
          <multi-event-minimalist-card
            :events="drafts.elements"
            :showOrganizer="true"
          />
          <o-pagination
            class="mt-4"
            v-show="drafts.total > LOGGED_USER_DRAFTS_LIMIT"
            :total="drafts.total"
            v-model:current="draftsPage"
            :per-page="LOGGED_USER_DRAFTS_LIMIT"
            :aria-next-label="t('Next page')"
            :aria-previous-label="t('Previous page')"
            :aria-page-label="t('Page')"
            :aria-current-label="t('Current page')"
          >
          </o-pagination>
        </section>
        <section
          class="py-4 first:pt-0"
          v-if="
            showUpcoming && monthlyFutureEvents && monthlyFutureEvents.size > 0
          "
        >
          <transition-group name="list" tag="p">
            <div
              class="mb-5"
              v-for="month of monthlyFutureEvents"
              :key="month[0]"
            >
              <h2 class="text-2xl">{{ month[0] }}</h2>
              <div v-for="element in month[1]" :key="element.id">
                <event-participation-card
                  v-if="'role' in element"
                  :participation="element"
                  @event-deleted="eventDeleted"
                  class="participation"
                />
                <event-minimalist-card
                  v-else-if="
                    element.id &&
                    !monthParticipationsIds(month[1]).includes(element?.id)
                  "
                  :event="element"
                  class="participation"
                />
              </div>
            </div>
          </transition-group>
          <div class="columns is-centered">
            <o-button
              class="column is-narrow"
              v-if="
                hasMoreFutureParticipations &&
                futureParticipations &&
                futureParticipations.length === limit
              "
              @click="loadMoreFutureParticipations"
              size="large"
              variant="primary"
              >{{ t("Load more") }}</o-button
            >
          </div>
        </section>
        <section
          class="text-center not-found"
          v-if="
            showUpcoming &&
            monthlyFutureEvents &&
            monthlyFutureEvents.size === 0 &&
            true // !$apollo.loading
          "
        >
          <div class="text-center prose dark:prose-invert max-w-full">
            <p>
              {{
                t(
                  "You don't have any upcoming events. Maybe try another filter?"
                )
              }}
            </p>
            <i18n-t
              keypath="Do you wish to {create_event} or {explore_events}?"
              tag="p"
            >
              <template #create_event>
                <router-link :to="{ name: RouteName.CREATE_EVENT }">{{
                  t("create an event")
                }}</router-link>
              </template>
              <template #explore_events>
                <router-link
                  :to="{
                    name: RouteName.SEARCH,
                    query: { contentType: ContentType.EVENTS },
                  }"
                  >{{ t("explore the events") }}</router-link
                >
              </template>
            </i18n-t>
          </div>
        </section>
        <section v-if="!showUpcoming && pastParticipations.elements.length > 0">
          <transition-group name="list" tag="p">
            <div v-for="month in monthlyPastParticipations" :key="month[0]">
              <h2 class="capitalize inline-block relative">{{ month[0] }}</h2>
              <event-participation-card
                v-for="participation in month[1]"
                :key="participation.id"
                :participation="participation as IParticipant"
                :options="{ hideDate: false }"
                @event-deleted="eventDeleted"
                class="participation"
              />
            </div>
          </transition-group>
          <div class="columns is-centered">
            <o-button
              class="column is-narrow"
              v-if="
                hasMorePastParticipations &&
                pastParticipations.elements.length === limit
              "
              @click="loadMorePastParticipations"
              size="large"
              variant="primary"
              >{{ t("Load more") }}</o-button
            >
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ParticipantRole, ContentType } from "@/types/enums";
import RouteName from "@/router/name";
import type { IParticipant } from "../../types/participant.model";
import { LOGGED_USER_DRAFTS } from "../../graphql/actor";
import type { IEvent } from "../../types/event.model";
import MultiEventMinimalistCard from "../../components/Event/MultiEventMinimalistCard.vue";
import EventMinimalistCard from "../../components/Event/EventMinimalistCard.vue";
import {
  LOGGED_USER_PARTICIPATIONS,
  LOGGED_USER_UPCOMING_EVENTS,
} from "@/graphql/participant";
import { useApolloClient, useQuery } from "@vue/apollo-composable";
import { computed, inject, ref, defineAsyncComponent } from "vue";
import { IUser } from "@/types/current-user.model";
import {
  booleanTransformer,
  integerTransformer,
  useRouteQuery,
} from "vue-use-route-query";
import { Locale } from "date-fns";
import { useI18n } from "vue-i18n";
import { useRestrictions } from "@/composition/apollo/config";
import { useHead } from "@/utils/head";

const EventParticipationCard = defineAsyncComponent(
  () => import("@/components/Event/EventParticipationCard.vue")
);

type Eventable = IParticipant | IEvent;

const { t } = useI18n({ useScope: "global" });

const futurePage = ref(1);
const pastPage = ref(1);
const limit = ref(10);

function startOfDay(d: Date): string {
  const pad = (n: int): string => {
    return (n > 9 ? "" : "0") + n.toString();
  };
  return (
    d.getFullYear() +
    "-" +
    pad(d.getMonth() + 1) +
    "-" +
    pad(d.getDate()) +
    "T00:00:00Z"
  );
}

const showUpcoming = useRouteQuery("showUpcoming", true, booleanTransformer);
const showDrafts = useRouteQuery("showDrafts", true, booleanTransformer);
const showAttending = useRouteQuery("showAttending", true, booleanTransformer);
const showMyGroups = useRouteQuery("showMyGroups", false, booleanTransformer);
const dateFilter = useRouteQuery("dateFilter", startOfDay(new Date()), {
  fromQuery(query) {
    if (query && /(\d{4}-\d{2}-\d{2})/.test(query)) {
      return `${query}T00:00:00Z`;
    }
    return startOfDay(new Date());
  },
  toQuery(value: string) {
    return value.slice(0, 10);
  },
});

// bridge between datepicker expecting a Date object and dateFilter being a string
const datePick = computed({
  get: () => {
    return new Date(dateFilter.value);
  },
  set: (d: Date) => {
    dateFilter.value = startOfDay(d);
  },
});

const hasMoreFutureParticipations = ref(true);
const hasMorePastParticipations = ref(true);

const {
  result: loggedUserUpcomingEventsResult,
  fetchMore: fetchMoreUpcomingEvents,
} = useQuery<{
  loggedUser: IUser;
}>(LOGGED_USER_UPCOMING_EVENTS, () => ({
  page: 1,
  limit: 10,
  afterDateTime: dateFilter.value,
}));

const futureParticipations = computed(
  () =>
    loggedUserUpcomingEventsResult.value?.loggedUser.participations.elements ??
    []
);
const groupEvents = computed(
  () =>
    loggedUserUpcomingEventsResult.value?.loggedUser.followedGroupEvents
      .elements ?? []
);

const LOGGED_USER_DRAFTS_LIMIT = 10;
const draftsPage = useRouteQuery("draftsPage", 1, integerTransformer);

const { result: draftsResult } = useQuery<{
  loggedUser: Pick<IUser, "drafts">;
}>(
  LOGGED_USER_DRAFTS,
  () => ({ page: draftsPage.value, limit: LOGGED_USER_DRAFTS_LIMIT }),
  () => ({ fetchPolicy: "cache-and-network" })
);
const drafts = computed(() => draftsResult.value?.loggedUser.drafts);

const { result: participationsResult, fetchMore: fetchMoreParticipations } =
  useQuery<{
    loggedUser: Pick<IUser, "participations">;
  }>(LOGGED_USER_PARTICIPATIONS, () => ({ page: 1, limit: 10 }));
const pastParticipations = computed(
  () =>
    participationsResult.value?.loggedUser.participations ?? {
      elements: [],
      total: 0,
    }
);

const monthlyEvents = (elements: Eventable[]): Map<string, Eventable[]> => {
  const res = elements.filter((element: Eventable) => {
    if ("role" in element) {
      return (
        element.event.beginsOn != null &&
        element.role !== ParticipantRole.REJECTED
      );
    }
    return element.beginsOn != null;
  });
  // sort by start date, ascending
  res.sort((a: Eventable, b: Eventable) => {
    const aTime = "role" in a ? a.event.beginsOn : a.beginsOn;
    const bTime = "role" in b ? b.event.beginsOn : b.beginsOn;
    return new Date(aTime).getTime() - new Date(bTime).getTime();
  });
  return res.reduce((acc: Map<string, Eventable[]>, element: Eventable) => {
    const month = new Date(
      "role" in element ? element.event.beginsOn : element.beginsOn
    ).toLocaleDateString(undefined, {
      year: "numeric",
      month: "long",
    });
    const filteredElements: Eventable[] = acc.get(month) || [];
    filteredElements.push(element);
    acc.set(month, filteredElements);
    return acc;
  }, new Map());
};

const monthlyFutureEvents = computed((): Map<string, Eventable[]> => {
  let eventable = [] as Eventable[];
  if (showAttending.value) {
    eventable = [...eventable, ...futureParticipations.value];
  }
  if (showMyGroups.value) {
    eventable = [...eventable, ...groupEvents.value.map(({ event }) => event)];
  }
  return monthlyEvents(eventable);
});

const monthlyPastParticipations = computed((): Map<string, Eventable[]> => {
  return monthlyEvents(pastParticipations.value.elements, true);
});

const monthParticipationsIds = (elements: Eventable[]): string[] => {
  const res = elements.filter((element: Eventable) => {
    return "role" in element;
  }) as IParticipant[];
  return res.map(({ event }: { event: IEvent }) => {
    return event.id as string;
  });
};

const loadMoreFutureParticipations = (): void => {
  futurePage.value += 1;
  if (fetchMoreUpcomingEvents) {
    fetchMoreUpcomingEvents({
      // New variables
      variables: {
        page: futurePage.value,
        limit: limit.value,
      },
    });
  }
};

const loadMorePastParticipations = (): void => {
  pastPage.value += 1;
  if (fetchMoreParticipations) {
    fetchMoreParticipations({
      // New variables
      variables: {
        page: pastPage.value,
        limit: limit.value,
      },
    });
  }
};

const apollo = useApolloClient();

const eventDeleted = (eventid: string): void => {
  /**
   * Remove event from upcoming event participations
   */
  const upcomingEventsData = apollo.client.cache.readQuery<{
    loggedUser: IUser;
  }>({
    query: LOGGED_USER_UPCOMING_EVENTS,
    variables: () => ({
      page: 1,
      limit: 10,
      afterDateTime: dateFilter.value,
    }),
  });
  if (!upcomingEventsData) return;
  const loggedUser = upcomingEventsData?.loggedUser;
  const participations = loggedUser?.participations;
  apollo.client.cache.writeQuery<{ loggedUser: IUser }>({
    query: LOGGED_USER_UPCOMING_EVENTS,
    variables: () => ({
      page: 1,
      limit: 10,
      afterDateTime: dateFilter.value,
    }),
    data: {
      loggedUser: {
        ...loggedUser,
        participations: {
          total: participations.total - 1,
          elements: participations.elements.filter(
            (participation) => participation.event.id !== eventid
          ),
        },
      },
    },
  });

  /**
   * Remove event from past event participations
   */
  const participationData = apollo.client.cache.readQuery<{
    loggedUser: Pick<IUser, "participations">;
  }>({
    query: LOGGED_USER_PARTICIPATIONS,
    variables: () => ({ page: 1, limit: 10 }),
  });
  if (!participationData) return;
  const loggedUser2 = participationData?.loggedUser;
  const participations2 = loggedUser?.participations;
  apollo.client.cache.writeQuery<{
    loggedUser: Pick<IUser, "participations">;
  }>({
    query: LOGGED_USER_PARTICIPATIONS,
    variables: () => ({ page: 1, limit: 10 }),
    data: {
      loggedUser: {
        ...loggedUser2,
        participations: {
          total: participations2.total - 1,
          elements: participations2.elements.filter(
            (participation) => participation.event.id !== eventid
          ),
        },
      },
    },
  });
};

const { restrictions } = useRestrictions();

const hideCreateEventButton = computed((): boolean => {
  return restrictions.value?.onlyGroupsCanCreateEvents === true;
});

const dateFnsLocale = inject<Locale>("dateFnsLocale");

const firstDayOfWeek = computed((): number => {
  return dateFnsLocale?.options?.weekStartsOn ?? 0;
});

useHead({
  title: computed(() => t("My events")),
});
</script>
