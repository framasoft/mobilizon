<template>
  <div class="max-w-4xl mx-auto">
    <search-fields
      class="md:ml-10 mr-2"
      v-model:search="search"
      v-model:address="address"
      v-model:distance="radius"
      :addressDefaultText="addressName"
      :fromLocalStorage="true"
    />
  </div>
  <div
    class="container mx-auto md:py-3 md:px-4 flex flex-col lg:flex-row gap-x-5 gap-y-1"
  >
    <aside
      class="flex-none lg:block lg:sticky top-8 rounded-md w-full lg:w-80 flex-col justify-between mt-2 lg:pb-10 lg:px-8 overflow-y-auto dark:text-slate-100 bg-white dark:bg-mbz-purple"
    >
      <o-button
        @click="toggleFilters"
        icon-left="filter"
        class="w-full inline-flex lg:!hidden text-white px-4 py-2 justify-center"
      >
        <span v-if="!filtersPanelOpened">{{ t("Hide filters") }}</span>
        <span v-else>{{ t("Show filters") }}</span>
      </o-button>
      <form
        @submit.prevent="doNewSearch"
        :class="{ hidden: filtersPanelOpened }"
        class="lg:block mt-4 px-2"
      >
        <div
          class="py-4 border-b border-gray-200 dark:border-gray-500"
          v-show="globalSearchEnabled"
        >
          <fieldset class="flex flex-col">
            <legend class="sr-only">{{ t("Search target") }}</legend>

            <div>
              <input
                id="selfTarget"
                v-model="searchTarget"
                type="radio"
                name="selfTarget"
                :value="SearchTargets.SELF"
                class="w-4 h-4 border-gray-300 focus:ring-2 focus:ring-blue-300 dark:focus:ring-blue-600 dark:focus:bg-blue-600 dark:bg-gray-700 dark:border-gray-600"
              />
              <label
                for="selfTarget"
                class="cursor-pointer ml-3 font-medium text-gray-900 dark:text-gray-300"
                >{{ t("From this instance only") }}</label
              >
            </div>

            <div>
              <input
                id="internalTarget"
                v-model="searchTarget"
                type="radio"
                name="searchTarget"
                :value="SearchTargets.INTERNAL"
                class="w-4 h-4 border-gray-300 focus:ring-2 focus:ring-blue-300 dark:focus:ring-blue-600 dark:focus:bg-blue-600 dark:bg-gray-700 dark:border-gray-600"
              />
              <label
                for="internalTarget"
                class="cursor-pointer ml-3 font-medium text-gray-900 dark:text-gray-300"
                >{{ t("In this instance's network") }}</label
              >
            </div>
          </fieldset>
        </div>

        <div
          class="py-4 border-b border-gray-200 dark:border-gray-500"
          v-show="contentType !== 'GROUPS'"
        >
          <o-switch v-model="isOnline">{{ t("Online events") }}</o-switch>
        </div>

        <filter-section
          v-show="contentType !== 'GROUPS'"
          v-model:opened="searchFilterSectionsOpenStatus.eventDate"
          :title="t('Event date')"
        >
          <template #options>
            <fieldset class="flex flex-col">
              <legend class="sr-only">{{ t("Event date") }}</legend>
              <div
                v-for="(eventStartDateRangeOption, key) in dateOptions"
                :key="key"
              >
                <input
                  :id="key"
                  v-model="when"
                  type="radio"
                  name="eventStartDateRange"
                  :value="key"
                  class="w-4 h-4 border-gray-300 focus:ring-2 focus:ring-blue-300 dark:focus:ring-blue-600 dark:focus:bg-blue-600 dark:bg-gray-700 dark:border-gray-600"
                />
                <label
                  :for="key"
                  class="cursor-pointer ml-3 text-sm font-medium text-gray-900 dark:text-gray-300"
                  >{{ eventStartDateRangeOption.label }}</label
                >
              </div>
            </fieldset>
          </template>
          <template #preview>
            <span
              class="bg-blue-100 text-blue-800 text-sm font-semibold p-0.5 rounded dark:bg-blue-200 dark:text-blue-800 grow-0"
            >
              {{
                Object.entries(dateOptions).find(([key]) => key === when)?.[1]
                  ?.label
              }}
            </span>
          </template>
        </filter-section>

        <filter-section
          v-show="contentType !== 'GROUPS'"
          v-model:opened="searchFilterSectionsOpenStatus.eventCategory"
          :title="t('Categories')"
        >
          <template #options>
            <fieldset class="flex flex-col">
              <legend class="sr-only">{{ t("Categories") }}</legend>
              <div v-for="category in orderedCategories" :key="category.id">
                <input
                  :id="category.id"
                  v-model="categoryOneOf"
                  type="checkbox"
                  name="category"
                  :value="category.id"
                  class="w-4 h-4 border-gray-300 focus:ring-2 focus:ring-blue-300 dark:focus:ring-blue-600 dark:focus:bg-blue-600 dark:bg-gray-700 dark:border-gray-600"
                />
                <label
                  :for="category.id"
                  class="cursor-pointer ml-3 text-sm font-medium text-gray-900 dark:text-gray-300"
                  >{{ category.label }}</label
                >
              </div>
            </fieldset>
          </template>
          <template #preview>
            <span
              class="bg-blue-100 text-blue-800 text-sm font-semibold p-0.5 rounded dark:bg-blue-200 dark:text-blue-800 grow-0"
              v-if="categoryOneOf.length > 2"
            >
              {{
                t("{numberOfCategories} selected", {
                  numberOfCategories: categoryOneOf.length,
                })
              }}
            </span>
            <span
              class="bg-blue-100 text-blue-800 text-sm font-semibold p-0.5 rounded dark:bg-blue-200 dark:text-blue-800 grow-0"
              v-else-if="categoryOneOf.length > 0"
            >
              {{
                listShortDisjunctionFormatter(
                  categoryOneOf.map(
                    (category) =>
                      (eventCategories ?? []).find(({ id }) => id === category)
                        ?.label ?? ""
                  )
                )
              }}
            </span>
            <span
              class="bg-blue-100 text-blue-800 text-sm font-semibold p-0.5 rounded dark:bg-blue-200 dark:text-blue-800 grow-0"
              v-else-if="categoryOneOf.length === 0"
            >
              {{ t("Categories", "All") }}
            </span>
          </template>
        </filter-section>
        <filter-section
          v-show="contentType !== 'GROUPS'"
          v-model:opened="searchFilterSectionsOpenStatus.eventStatus"
          :title="t('Event status')"
        >
          <template #options>
            <fieldset class="flex flex-col">
              <legend class="sr-only">{{ t("Event status") }}</legend>
              <div
                v-for="eventStatusOption in eventStatuses"
                :key="eventStatusOption.id"
              >
                <input
                  :id="eventStatusOption.id"
                  v-model="statusOneOf"
                  type="checkbox"
                  name="eventStatus"
                  :value="eventStatusOption.id"
                  class="w-4 h-4 border-gray-300 focus:ring-2 focus:ring-blue-300 dark:focus:ring-blue-600 dark:focus:bg-blue-600 dark:bg-gray-700 dark:border-gray-600"
                />
                <label
                  :for="eventStatusOption.id"
                  class="cursor-pointer ml-3 text-sm font-medium text-gray-900 dark:text-gray-300"
                  >{{ eventStatusOption.label }}</label
                >
              </div>
            </fieldset>
          </template>
          <template #preview>
            <span
              class="bg-blue-100 text-blue-800 text-sm font-semibold p-0.5 rounded dark:bg-blue-200 dark:text-blue-800 grow-0"
              v-if="statusOneOf.length === Object.values(EventStatus).length"
            >
              {{ t("Statuses", "All") }}
            </span>
            <span
              class="bg-blue-100 text-blue-800 text-sm font-semibold p-0.5 rounded dark:bg-blue-200 dark:text-blue-800 grow-0"
              v-else-if="statusOneOf.length > 0"
            >
              {{
                listShortDisjunctionFormatter(
                  statusOneOf.map(
                    (status) =>
                      eventStatuses.find(({ id }) => id === status)?.label ?? ""
                  )
                )
              }}
            </span>
          </template>
        </filter-section>

        <filter-section
          v-model:opened="searchFilterSectionsOpenStatus.eventLanguage"
          :title="t('Languages')"
        >
          <template #options>
            <fieldset class="flex flex-col">
              <legend class="sr-only">{{ t("Languages") }}</legend>
              <div v-for="(language, key) in langs" :key="key">
                <input
                  :id="key"
                  type="checkbox"
                  name="eventStartDateRange"
                  :value="key"
                  v-model="languageOneOf"
                  class="w-4 h-4 border-gray-300 focus:ring-2 focus:ring-blue-300 dark:focus:ring-blue-600 dark:focus:bg-blue-600 dark:bg-gray-700 dark:border-gray-600"
                />
                <label
                  :for="key"
                  class="cursor-pointer ml-3 text-sm font-medium text-gray-900 dark:text-gray-300"
                  >{{ language }}</label
                >
              </div>
            </fieldset>
          </template>
          <template #preview>
            <span
              class="bg-blue-100 text-blue-800 text-sm font-semibold p-0.5 rounded dark:bg-blue-200 dark:text-blue-800 grow-0"
              v-if="languageOneOf.length > 2"
            >
              {{
                t("{numberOfLanguages} selected", {
                  numberOfLanguages: languageOneOf.length,
                })
              }}
            </span>
            <span
              class="bg-blue-100 text-blue-800 text-sm font-semibold p-0.5 rounded dark:bg-blue-200 dark:text-blue-800 grow-0"
              v-else-if="languageOneOf.length > 0"
            >
              {{
                listShortDisjunctionFormatter(
                  languageOneOf.map((lang) => langs[lang])
                )
              }}
            </span>
            <span
              class="bg-blue-100 text-blue-800 text-sm font-semibold p-0.5 rounded dark:bg-blue-200 dark:text-blue-800 grow-0"
              v-else-if="languageOneOf.length === 0"
            >
              {{ t("Languages", "All") }}
            </span>
          </template>
        </filter-section>

        <div class="sr-only">
          <button
            class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center mr-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
            type="submit"
          >
            {{ t("Apply filters") }}
          </button>
        </div>

        <o-button
          @click="toggleFilters"
          icon-left="filter"
          class="w-full inline-flex lg:!hidden text-white px-4 py-2 justify-center"
        >
          {{ t("Hide filters") }}
        </o-button>
      </form>
    </aside>
    <div class="flex-1 px-2">
      <div
        id="results-anchor"
        class="hidden sm:flex items-center justify-between dark:text-slate-100 mb-2"
      >
        <p v-if="searchLoading">{{ t("Loading search results...") }}</p>
        <p v-else-if="totalCount === 0">
          <span v-if="contentType === ContentType.EVENTS">{{
            t("No events found")
          }}</span>
          <span v-else-if="contentType === ContentType.LONGEVENTS">{{
            t("No activities found")
          }}</span>
          <span v-else-if="contentType === ContentType.GROUPS">{{
            t("No groups found")
          }}</span>
          <span v-else>{{ t("No results found") }}</span>
        </p>
        <p v-else>
          <span v-if="contentType === ContentType.EVENTS">
            {{
              t(
                "{eventsCount} events found",
                { eventsCount: searchEvents?.total },
                searchEvents?.total ?? 0
              )
            }}
          </span>
          <span v-else-if="contentType === ContentType.LONGEVENTS">
            {{
              t(
                "{eventsCount} activities found",
                { eventsCount: searchEvents?.total },
                searchEvents?.total ?? 0
              )
            }}
          </span>
          <span v-else-if="contentType === ContentType.GROUPS">
            {{
              t(
                "{groupsCount} groups found",
                { groupsCount: searchGroups?.total },
                searchGroups?.total ?? 0
              )
            }}
          </span>
          <span v-else>
            {{
              t(
                "{resultsCount} results found",
                { resultsCount: totalCount },
                totalCount
              )
            }}
          </span>
        </p>
        <div class="flex gap-2">
          <label class="sr-only" for="sortOptionSelect">{{
            t("Sort by")
          }}</label>
          <o-select
            v-if="contentType !== ContentType.GROUPS"
            :placeholder="t('Sort by events')"
            v-model="sortByEvents"
            id="sortOptionSelectEvents"
          >
            <option
              v-for="sortOption in sortOptionsEvents"
              :key="sortOption.key"
              :value="sortOption.key"
            >
              {{ sortOption.label }}
            </option>
          </o-select>
          <o-select
            v-if="contentType === ContentType.GROUPS"
            :placeholder="t('Sort by groups')"
            v-model="sortByGroups"
            id="sortOptionSelectGroups"
          >
            <option
              v-for="sortOption in sortOptionsGroups"
              :key="sortOption.key"
              :value="sortOption.key"
            >
              {{ sortOption.label }}
            </option>
          </o-select>
          <o-button
            v-show="!isOnline"
            @click="
              () =>
                (mode = mode === ViewMode.MAP ? ViewMode.LIST : ViewMode.MAP)
            "
            :icon-left="mode === ViewMode.MAP ? 'view-list' : 'map'"
          >
            <span v-if="mode === ViewMode.LIST">
              {{ t("Map") }}
            </span>
            <span v-else-if="mode === ViewMode.MAP">
              {{ t("List") }}
            </span>
          </o-button>
        </div>
      </div>
      <div v-if="mode === ViewMode.LIST">
        <template
          v-if="
            contentType === ContentType.EVENTS ||
            contentType === ContentType.LONGEVENTS
          "
        >
          <template v-if="searchLoading">
            <SkeletonEventResultList v-for="i in 8" :key="i" />
          </template>
          <template v-if="searchEvents && searchEvents.total > 0">
            <event-card
              mode="row"
              v-for="event in searchEvents?.elements"
              :event="event"
              :key="event.uuid"
              :options="{
                isRemoteEvent: event.__typename === 'EventResult',
                isLoggedIn: currentUser?.isLoggedIn,
              }"
              class="my-4"
            />
            <o-pagination
              v-show="searchEvents && searchEvents?.total > EVENT_PAGE_LIMIT"
              :total="searchEvents.total"
              v-model:current="eventPage"
              :per-page="EVENT_PAGE_LIMIT"
              :aria-next-label="t('Next page')"
              :aria-previous-label="t('Previous page')"
              :aria-page-label="t('Page')"
              :aria-current-label="t('Current page')"
            >
            </o-pagination>
          </template>
          <EmptyContent
            v-else-if="searchLoading === false"
            :icon="
              contentType === ContentType.LONGEVENTS
                ? 'calendar-star'
                : 'calendar'
            "
          >
            <span v-if="searchIsUrl">
              {{ t("No event found at this address") }}
            </span>
            <span v-else-if="!search && contentType !== ContentType.LONGEVENTS">
              {{ t("No events found") }}
            </span>
            <span v-else-if="!search && contentType === ContentType.LONGEVENTS">
              {{ t("No activities found") }}
            </span>
            <i18n-t keypath="No events found for {search}" tag="span" v-else>
              <template #search>
                <b>{{ search }}</b>
              </template>
            </i18n-t>
            <template #desc v-if="searchIsUrl && !currentUser?.id">
              {{
                t(
                  "Only registered users may fetch remote events from their URL."
                )
              }}
            </template>
            <template #desc v-else>
              <p class="my-2 text-start">
                {{ t("Suggestions:") }}
              </p>
              <ul class="list-disc list-inside text-start">
                <li>
                  {{ t("Make sure that all words are spelled correctly.") }}
                </li>
                <li>{{ t("Try different keywords.") }}</li>
                <li>{{ t("Try more general keywords.") }}</li>
                <li>{{ t("Try fewer keywords.") }}</li>
                <li>{{ t("Change the filters.") }}</li>
              </ul>
            </template>
          </EmptyContent>
        </template>
        <template v-else-if="contentType === ContentType.GROUPS">
          <o-notification v-if="features && !features.groups" variant="danger">
            {{ t("Groups are not enabled on this instance.") }}
          </o-notification>
          <template v-else-if="searchLoading">
            <SkeletonGroupResultList v-for="i in 6" :key="i" />
          </template>
          <template v-else-if="searchGroups && searchGroups?.total > 0">
            <GroupCard
              class="my-2"
              v-for="group in searchGroups?.elements"
              :group="group"
              :key="group.id"
              :isRemoteGroup="group.__typename === 'GroupResult'"
              :isLoggedIn="currentUser?.isLoggedIn"
              mode="row"
            />
            <o-pagination
              v-show="searchGroups && searchGroups?.total > GROUP_PAGE_LIMIT"
              :total="searchGroups?.total"
              v-model:current="groupPage"
              :per-page="GROUP_PAGE_LIMIT"
              :aria-next-label="t('Next page')"
              :aria-previous-label="t('Previous page')"
              :aria-page-label="t('Page')"
              :aria-current-label="t('Current page')"
            >
            </o-pagination>
          </template>
          <EmptyContent
            v-else-if="searchLoading === false"
            icon="account-multiple"
          >
            <span v-if="!search">
              {{ t("No groups found") }}
            </span>
            <i18n-t keypath="No groups found for {search}" tag="span" v-else>
              <template #search>
                <b>{{ search }}</b>
              </template>
            </i18n-t>
            <template #desc>
              <p class="my-2 text-start">
                {{ t("Suggestions:") }}
              </p>
              <ul class="list-disc list-inside text-start">
                <li>
                  {{ t("Make sure that all words are spelled correctly.") }}
                </li>
                <li>{{ t("Try different keywords.") }}</li>
                <li>{{ t("Try more general keywords.") }}</li>
                <li>{{ t("Try fewer keywords.") }}</li>
                <li>{{ t("Change the filters.") }}</li>
              </ul>
            </template>
          </EmptyContent>
        </template>
      </div>
      <event-marker-map
        v-if="mode === ViewMode.MAP"
        :contentType="contentType"
        :latitude="latitude"
        :longitude="longitude"
        :locationName="addressName"
        @map-updated="setBounds"
        :events="searchEvents"
        :groups="searchGroups"
        :isLoggedIn="currentUser?.isLoggedIn"
      />
    </div>
  </div>
</template>

<script lang="ts" setup>
import {
  endOfToday,
  addDays,
  startOfDay,
  endOfDay,
  endOfWeek,
  addWeeks,
  startOfWeek,
  endOfMonth,
  addMonths,
  startOfMonth,
  eachWeekendOfInterval,
} from "date-fns";
import { ContentType, EventStatus, SearchTargets } from "@/types/enums";
import EventCard from "@/components/Event/EventCard.vue";
import { IEvent } from "@/types/event.model";
import { SEARCH_EVENTS_AND_GROUPS } from "@/graphql/search";
import { Paginate } from "@/types/paginate";
import { IGroup } from "@/types/actor";
import GroupCard from "@/components/Group/GroupCard.vue";
import { CURRENT_USER_CLIENT } from "@/graphql/user";
import { ICurrentUser } from "@/types/current-user.model";
import { useQuery } from "@vue/apollo-composable";
import { computed, defineAsyncComponent, inject, ref, watch } from "vue";
import { useI18n } from "vue-i18n";
import {
  floatTransformer,
  integerTransformer,
  useRouteQuery,
  enumTransformer,
  booleanTransformer,
} from "vue-use-route-query";

import { useHead } from "@/utils/head";
import type { Locale } from "date-fns";
import FilterSection from "@/components/Search/filters/FilterSection.vue";
import { listShortDisjunctionFormatter } from "@/utils/listFormat";
import langs from "@/i18n/langs.json";
import {
  useEventCategories,
  useFeatures,
  useSearchConfig,
} from "@/composition/apollo/config";
import { coordsToGeoHash } from "@/utils/location";
import SearchFields from "@/components/Home/SearchFields.vue";
import { refDebounced } from "@vueuse/core";
import { IAddress } from "@/types/address.model";
import { IConfig } from "@/types/config.model";
import { TypeNamed } from "@/types/apollo";
import { LatLngBounds } from "leaflet";
import lodashSortBy from "lodash/sortBy";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import SkeletonGroupResultList from "@/components/Group/SkeletonGroupResultList.vue";
import SkeletonEventResultList from "@/components/Event/SkeletonEventResultList.vue";
import { arrayTransformer } from "@/utils/route";

const EventMarkerMap = defineAsyncComponent(
  () => import("@/components/Search/EventMarkerMap.vue")
);

const search = useRouteQuery("search", "");
const searchDebounced = refDebounced(search, 1000);
const addressName = useRouteQuery("locationName", null);
const address = ref<IAddress | null>(null);

watch(address, (newAddress: IAddress) => {
  console.debug("address change", newAddress);
  if (newAddress?.geom) {
    latitude.value = parseFloat(newAddress?.geom.split(";")[1]);
    longitude.value = parseFloat(newAddress?.geom.split(";")[0]);
    addressName.value = newAddress?.description;
    console.debug("set address", [
      latitude.value,
      longitude.value,
      addressName.value,
    ]);
  } else {
    console.debug("address emptied");
    latitude.value = undefined;
    longitude.value = undefined;
    addressName.value = null;
  }
});

interface ISearchTimeOption {
  label: string;
  start?: string | null;
  end?: string | null;
}

enum ViewMode {
  LIST = "list",
  MAP = "map",
}

enum EventSortValues {
  CREATED_AT_ASC = "CREATED_AT_ASC",
  CREATED_AT_DESC = "CREATED_AT_DESC",
  START_TIME_ASC = "START_TIME_ASC",
  START_TIME_DESC = "START_TIME_DESC",
  PARTICIPANT_COUNT_DESC = "PARTICIPANT_COUNT_DESC",
}

enum GroupSortValues {
  CREATED_AT_DESC = "CREATED_AT_DESC",
  MEMBER_COUNT_DESC = "MEMBER_COUNT_DESC",
  LAST_EVENT_ACTIVITY = "LAST_EVENT_ACTIVITY",
}

const props = defineProps<{
  tag?: string;
}>();
const tag = computed(() => props.tag);

const eventPage = useRouteQuery("eventPage", 1, integerTransformer);
const groupPage = useRouteQuery("groupPage", 1, integerTransformer);

const latitude = useRouteQuery("lat", undefined, floatTransformer);
const longitude = useRouteQuery("lon", undefined, floatTransformer);

const distance = useRouteQuery("distance", "10_km");
const when = useRouteQuery("when", "any");
const contentType = useRouteQuery(
  "contentType",
  ContentType.EVENTS,
  enumTransformer(ContentType)
);
const isOnline = useRouteQuery("isOnline", false, booleanTransformer);
const categoryOneOf = useRouteQuery("categoryOneOf", [], arrayTransformer);
const statusOneOf = useRouteQuery(
  "statusOneOf",
  [EventStatus.CONFIRMED],
  arrayTransformer
);
const languageOneOf = useRouteQuery("languageOneOf", [], arrayTransformer);

const searchTarget = useRouteQuery(
  "target",
  SearchTargets.INTERNAL,
  enumTransformer(SearchTargets)
);
const mode = useRouteQuery("mode", ViewMode.LIST, enumTransformer(ViewMode));
const sortByEvents = useRouteQuery(
  "sortByEvents",
  EventSortValues.START_TIME_ASC,
  enumTransformer(EventSortValues)
);
const sortByGroups = useRouteQuery(
  "sortByGroups",
  GroupSortValues.LAST_EVENT_ACTIVITY,
  enumTransformer(GroupSortValues)
);
const bbox = useRouteQuery("bbox", undefined);
const zoom = useRouteQuery("zoom", undefined, integerTransformer);

const EVENT_PAGE_LIMIT = 16;

const GROUP_PAGE_LIMIT = 16;

const { features } = useFeatures();
const { eventCategories } = useEventCategories();

const orderedCategories = computed(() => {
  if (!eventCategories.value) return [];
  return lodashSortBy(eventCategories.value, ["label"]);
});

const searchEvents = computed(() => searchElementsResult.value?.searchEvents);
const searchGroups = computed(() => searchElementsResult.value?.searchGroups);

const { result: currentUserResult } = useQuery<{ currentUser: ICurrentUser }>(
  CURRENT_USER_CLIENT
);

const currentUser = computed(() => currentUserResult.value?.currentUser);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Explore events")),
});

const dateFnsLocale = inject<Locale>("dateFnsLocale");

const weekend = computed((): { start: Date; end: Date } => {
  const now = new Date();
  const endOfWeekDate = endOfWeek(now, { locale: dateFnsLocale });
  const startOfWeekDate = startOfWeek(now, { locale: dateFnsLocale });
  const [start, end] = eachWeekendOfInterval({
    start: startOfWeekDate,
    end: endOfWeekDate,
  });
  return { start: startOfDay(start), end: endOfDay(end) };
});

const dateOptions: Record<string, ISearchTimeOption> = {
  past: {
    label: t("In the past") as string,
    start: null,
    end: new Date().toISOString(),
  },
  today: {
    label: t("Today") as string,
    start: new Date().toISOString(),
    end: endOfToday().toISOString(),
  },
  tomorrow: {
    label: t("Tomorrow") as string,
    start: startOfDay(addDays(new Date(), 1)).toISOString(),
    end: endOfDay(addDays(new Date(), 1)).toISOString(),
  },
  weekend: {
    label: t("This weekend") as string,
    start: weekend.value.start.toISOString(),
    end: weekend.value.end.toISOString(),
  },
  week: {
    label: t("This week") as string,
    start: new Date().toISOString(),
    end: endOfWeek(new Date(), { locale: dateFnsLocale }).toISOString(),
  },
  next_week: {
    label: t("Next week") as string,
    start: startOfWeek(addWeeks(new Date(), 1), {
      locale: dateFnsLocale,
    }).toISOString(),
    end: endOfWeek(addWeeks(new Date(), 1), {
      locale: dateFnsLocale,
    }).toISOString(),
  },
  month: {
    label: t("This month") as string,
    start: new Date().toISOString(),
    end: endOfMonth(new Date()).toISOString(),
  },
  next_month: {
    label: t("Next month") as string,
    start: startOfMonth(addMonths(new Date(), 1)).toISOString(),
    end: endOfMonth(addMonths(new Date(), 1)).toISOString(),
  },
  any: {
    label: t("Any day") as string,
    start: new Date().toISOString(),
    end: null,
  },
};

const start = computed((): string | undefined | null => {
  if (dateOptions[when.value]) {
    return dateOptions[when.value].start;
  }
  return undefined;
});

const end = computed((): string | undefined | null => {
  if (dateOptions[when.value]) {
    return dateOptions[when.value].end;
  }
  return undefined;
});

const searchIsUrl = computed((): boolean => {
  let url;
  if (!searchDebounced.value) return false;
  try {
    url = new URL(searchDebounced.value);
  } catch (_) {
    return false;
  }

  return url.protocol === "http:" || url.protocol === "https:";
});

const eventStatuses = computed(() => {
  return [
    {
      id: EventStatus.CONFIRMED,
      label: t("Confirmed"),
    },
    {
      id: EventStatus.TENTATIVE,
      label: t("Tentative"),
    },
    {
      id: EventStatus.CANCELLED,
      label: t("Cancelled"),
    },
  ];
});

const searchFilterSectionsOpenStatus = ref({
  eventDate: true,
  eventLanguage: false,
  eventCategory: false,
  eventStatus: false,
  eventDistance: false,
});

const filtersPanelOpened = ref(true);

const toggleFilters = () =>
  (filtersPanelOpened.value = !filtersPanelOpened.value);

const geoHashLocation = computed(() =>
  coordsToGeoHash(latitude.value, longitude.value)
);

const radius = computed({
  get(): number | null {
    if (addressName.value) {
      return Number.parseInt(distance.value.slice(0, -3));
    } else {
      return null;
    }
  },
  set(newRadius: number) {
    distance.value = newRadius.toString() + "_km";
  },
});

const longEvents = computed(() => {
  if (contentType.value === ContentType.EVENTS) {
    return false;
  } else if (contentType.value === ContentType.LONGEVENTS) {
    return true;
  } else {
    return null;
  }
});

const totalCount = computed(() => {
  return (searchEvents.value?.total ?? 0) + (searchGroups.value?.total ?? 0);
});

const sortOptionsGroups = computed(() => {
  const options = [
    {
      key: GroupSortValues.LAST_EVENT_ACTIVITY,
      label: t("Last event activity"),
    },
    {
      key: GroupSortValues.MEMBER_COUNT_DESC,
      label: t("Decreasing number of members"),
    },
    {
      key: GroupSortValues.CREATED_AT_DESC,
      label: t("Decreasing creation date"),
    },
  ];

  return options;
});

const sortOptionsEvents = computed(() => {
  const options = [
    {
      key: EventSortValues.START_TIME_ASC,
      label: t("Event date"),
    },
    {
      key: EventSortValues.CREATED_AT_DESC,
      label: t("Most recently published"),
    },
    {
      key: EventSortValues.CREATED_AT_ASC,
      label: t("Least recently published"),
    },
    {
      key: EventSortValues.PARTICIPANT_COUNT_DESC,
      label: t("With the most participants"),
    },
  ];

  return options;
});

const { searchConfig, onResult: onSearchConfigResult } = useSearchConfig();

onSearchConfigResult(({ data }) =>
  handleSearchConfigChanged(data?.config?.search)
);

const handleSearchConfigChanged = (
  searchConfigChanged: IConfig["search"] | undefined
) => {
  if (
    searchConfigChanged?.global?.isEnabled &&
    searchConfigChanged?.global?.isDefault
  ) {
    searchTarget.value = SearchTargets.INTERNAL;
  }
};

watch(searchConfig, (newSearchConfig) =>
  handleSearchConfigChanged(newSearchConfig)
);

const globalSearchEnabled = computed(
  () => searchConfig.value?.global?.isEnabled
);

const setBounds = ({
  bounds,
  zoom: boundsZoom,
}: {
  bounds: LatLngBounds;
  zoom: number;
}) => {
  bbox.value = `${bounds.getNorthWest().lat}, ${bounds.getNorthWest().lng}:${
    bounds.getSouthEast().lat
  }, ${bounds.getSouthEast().lng}`;
  zoom.value = boundsZoom;
};

watch(mode, (newMode) => {
  if (newMode === ViewMode.MAP) {
    isOnline.value = false;
  }
});

watch(isOnline, (newIsOnline) => {
  if (newIsOnline) {
    mode.value = ViewMode.LIST;
  }
});

const sortByForType = (
  value: EventSortValues,
  allowed: typeof EventSortValues
): EventSortValues | undefined => {
  if (value === EventSortValues.START_TIME_ASC && when.value === "past") {
    value = EventSortValues.START_TIME_DESC;
  }
  return Object.values(allowed).includes(value) ? value : undefined;
};

const boostLanguagesQuery = computed((): string[] => {
  const languages = new Set<string>();

  for (const completeLanguage of navigator.languages) {
    const language = completeLanguage.split("-")[0];

    if (Object.keys(langs).find((langKey) => langKey === language)) {
      languages.add(language);
    }
  }

  return Array.from(languages);
});

// When search criteria changes, reset page number to 1
watch(
  [
    contentType,
    searchDebounced,
    geoHashLocation,
    start,
    end,
    radius,
    isOnline,
    categoryOneOf,
    statusOneOf,
    languageOneOf,
    searchTarget,
    bbox,
    zoom,
    sortByEvents,
    sortByGroups,
    boostLanguagesQuery,
  ],
  ([newContentType]) => {
    switch (newContentType) {
      case ContentType.EVENTS:
        eventPage.value = 1;
        break;
      case ContentType.LONGEVENTS:
        eventPage.value = 1;
        break;
      case ContentType.GROUPS:
        groupPage.value = 1;
        break;
    }
  }
);

const { result: searchElementsResult, loading: searchLoading } = useQuery<{
  searchEvents: Paginate<TypeNamed<IEvent>>;
  searchGroups: Paginate<TypeNamed<IGroup>>;
}>(SEARCH_EVENTS_AND_GROUPS, () => ({
  term: searchDebounced.value,
  tags: tag.value,
  location: geoHashLocation.value,
  beginsOn: start.value,
  endsOn: end.value,
  longEvents: longEvents.value,
  radius: geoHashLocation.value ? radius.value : undefined,
  eventPage: eventPage.value,
  groupPage: groupPage.value,
  limit: EVENT_PAGE_LIMIT,
  type: isOnline.value ? "ONLINE" : undefined,
  categoryOneOf: categoryOneOf.value,
  statusOneOf: statusOneOf.value,
  languageOneOf: languageOneOf.value,
  searchTarget: searchTarget.value,
  bbox: mode.value === ViewMode.MAP ? bbox.value : undefined,
  zoom: zoom.value,
  sortByEvents: sortByForType(sortByEvents.value, EventSortValues),
  sortByGroups: sortByGroups.value,
  boostLanguages: boostLanguagesQuery.value,
}));
</script>
