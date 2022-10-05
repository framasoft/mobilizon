<template>
  <div class="max-w-4xl mx-auto">
    <SearchFields
      class="md:ml-10 mr-2"
      v-model:search="search"
      v-model:location="location"
      :locationDefaultText="locationName"
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
        <p class="sr-only">{{ t("Type") }}</p>
        <ul
          class="font-medium text-gray-900 dark:text-slate-100 space-y-4 pb-4 border-b border-gray-200 dark:border-gray-500"
        >
          <li
            v-for="content in contentTypeMapping"
            :key="content.contentType"
            class="flex gap-1"
          >
            <Magnify
              v-if="content.contentType === ContentType.ALL"
              :size="24"
            />

            <Calendar
              v-if="content.contentType === ContentType.EVENTS"
              :size="24"
            />

            <AccountMultiple
              v-if="content.contentType === ContentType.GROUPS"
              :size="24"
            />

            <router-link
              :to="{
                ...$route,
                query: { ...$route.query, contentType: content.contentType },
              }"
            >
              {{ content.label }}
            </router-link>
          </li>
        </ul>

        <div
          class="py-4 border-b border-gray-200 dark:border-gray-500"
          v-show="globalSearchEnabled"
        >
          <fieldset class="flex flex-col">
            <legend class="sr-only">{{ t("Search target") }}</legend>

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
                class="ml-3 font-medium text-gray-900 dark:text-gray-300"
                >{{ t("In this instance's network") }}</label
              >
            </div>
            <div>
              <input
                id="globalTarget"
                v-model="searchTarget"
                type="radio"
                name="searchTarget"
                :value="SearchTargets.GLOBAL"
                class="w-4 h-4 border-gray-300 focus:ring-2 focus:ring-blue-300 dark:focus:ring-blue-600 dark:focus:bg-blue-600 dark:bg-gray-700 dark:border-gray-600"
              />
              <label
                for="globalTarget"
                class="ml-3 font-medium text-gray-900 dark:text-gray-300"
                >{{ t("On the Fediverse") }}</label
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
                  class="ml-3 text-sm font-medium text-gray-900 dark:text-gray-300"
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
          v-show="!isOnline"
          v-model:opened="searchFilterSectionsOpenStatus.eventDistance"
          :title="t('Distance')"
        >
          <template #options>
            <fieldset class="flex flex-col">
              <legend class="sr-only">{{ t("Distance") }}</legend>
              <div
                v-for="distanceOption in eventDistance"
                :key="distanceOption.id"
              >
                <input
                  :id="distanceOption.id"
                  v-model="distance"
                  type="radio"
                  name="eventDistance"
                  :value="distanceOption.id"
                  class="w-4 h-4 border-gray-300 focus:ring-2 focus:ring-blue-300 dark:focus:ring-blue-600 dark:focus:bg-blue-600 dark:bg-gray-700 dark:border-gray-600"
                />
                <label
                  :for="distanceOption.id"
                  class="ml-3 text-sm font-medium text-gray-900 dark:text-gray-300"
                  >{{ distanceOption.label }}</label
                >
              </div>
            </fieldset>
          </template>
          <template #preview>
            <span
              class="bg-blue-100 text-blue-800 text-sm font-semibold p-0.5 rounded dark:bg-blue-200 dark:text-blue-800 grow-0"
            >
              {{ eventDistance.find(({ id }) => id === distance)?.label }}
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
              <div v-for="category in eventCategories" :key="category.id">
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
                  class="ml-3 text-sm font-medium text-gray-900 dark:text-gray-300"
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
                  class="ml-3 text-sm font-medium text-gray-900 dark:text-gray-300"
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
                  class="ml-3 text-sm font-medium text-gray-900 dark:text-gray-300"
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

        <!--

            <div class="">
              <label v-translate class="font-bold" for="host">Mobilizon instance</label>

              <input
                id="host"
                v-model="formHost"
                type="text"
                name="host"
                placeholder="mobilizon.fr"
                class="dark:text-black md:max-w-fit w-full"
              />
            </div>

            <div class="">
              <label v-translate class="inline font-bold" for="tagsAllOf">All of these tags</label>
              <button
                v-if="formTagsAllOf.length !== 0"
                v-translate
                class="text-sm ml-2"
                @click="resetField('tagsAllOf')"
              >
                Reset
              </button>

              <vue-tags-input
                v-model="formTagAllOf"
                :placeholder="tagsPlaceholder"
                :tags="formTagsAllOf"
                @tags-changed="(newTags) => (formTagsAllOf = newTags)"
              />
            </div>

            <div>
              <div>
                <label v-translate class="inline font-bold" for="tagsOneOf">One of these tags</label>
                <button
                  v-if="formTagsOneOf.length !== 0"
                  v-translate
                  class="text-sm ml-2"
                  @click="resetField('tagsOneOf')"
                >
                  Reset
                </button>
              </div>

              <vue-tags-input
                v-model="formTagOneOf"
                :placeholder="tagsPlaceholder"
                :tags="formTagsOneOf"
                @tags-changed="(newTags) => (formTagsOneOf = newTags)"
              />
            </div>-->

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
        <p v-if="totalCount === 0">
          <span v-if="contentType === ContentType.EVENTS">{{
            t("No events found")
          }}</span>
          <span v-else-if="contentType === ContentType.GROUPS">{{
            t("No groups found")
          }}</span>
          <span v-else>{{ t("No results found") }}</span>
        </p>
        <p v-else>
          <span v-if="contentType === 'EVENTS'">
            {{
              t(
                "{eventsCount} events found",
                { eventsCount: searchEvents?.total },
                searchEvents?.total ?? 0
              )
            }}
          </span>
          <span v-else-if="contentType === 'GROUPS'">
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
            :placeholder="t('Sort by')"
            v-model="sortBy"
            id="sortOptionSelect"
          >
            <option
              v-for="sortOption in sortOptions"
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
        <template v-if="contentType === ContentType.ALL">
          <o-notification v-if="features && !features.groups" variant="danger">
            {{ t("Groups are not enabled on this instance.") }}
          </o-notification>
          <div v-else-if="searchGroups && searchGroups?.total > 0">
            <GroupCard
              v-for="group in searchGroups?.elements"
              :group="group"
              :key="group.id"
              :isRemoteGroup="group.__typename === 'GroupResult'"
              :isLoggedIn="currentUser?.isLoggedIn"
              mode="row"
            />
            <o-pagination
              v-if="searchGroups && searchGroups?.total > GROUP_PAGE_LIMIT"
              :total="searchGroups?.total"
              v-model:current="groupPage"
              :per-page="GROUP_PAGE_LIMIT"
              :aria-next-label="t('Next page')"
              :aria-previous-label="t('Previous page')"
              :aria-page-label="t('Page')"
              :aria-current-label="t('Current page')"
            >
            </o-pagination>
          </div>
          <o-notification v-else-if="searchLoading === false" variant="danger">
            {{ t("No groups found") }}
          </o-notification>
          <div v-if="searchEvents && searchEvents.total > 0">
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
              v-if="searchEvents && searchEvents?.total > EVENT_PAGE_LIMIT"
              :total="searchEvents.total"
              v-model:current="eventPage"
              :per-page="EVENT_PAGE_LIMIT"
              :aria-next-label="t('Next page')"
              :aria-previous-label="t('Previous page')"
              :aria-page-label="t('Page')"
              :aria-current-label="t('Current page')"
            >
            </o-pagination>
          </div>
          <o-notification v-else-if="searchLoading === false" variant="info">
            <p>{{ t("No events found") }}</p>
            <p v-if="searchIsUrl && !currentUser?.id">
              {{
                t(
                  "Only registered users may fetch remote events from their URL."
                )
              }}
            </p>
          </o-notification>
        </template>
        <template v-else-if="contentType === ContentType.EVENTS">
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
          <o-notification v-else-if="searchLoading === false" variant="info">
            <p>{{ t("No events found") }}</p>
            <p v-if="searchIsUrl && !currentUser?.id">
              {{
                t(
                  "Only registered users may fetch remote events from their URL."
                )
              }}
            </p>
          </o-notification>
        </template>
        <template v-else-if="contentType === ContentType.GROUPS">
          <o-notification v-if="features && !features.groups" variant="danger">
            {{ t("Groups are not enabled on this instance.") }}
          </o-notification>

          <template v-else-if="searchGroups && searchGroups?.total > 0">
            <GroupCard
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
          <o-notification v-else-if="searchLoading === false" variant="danger">
            {{ t("No groups found") }}
          </o-notification>
        </template>
      </div>
      <event-marker-map
        v-if="mode === ViewMode.MAP"
        :contentType="contentType"
        :latitude="latitude"
        :longitude="longitude"
        :locationName="locationName"
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
  RouteQueryTransformer,
} from "vue-use-route-query";
import Calendar from "vue-material-design-icons/Calendar.vue";
import AccountMultiple from "vue-material-design-icons/AccountMultiple.vue";
import Magnify from "vue-material-design-icons/Magnify.vue";

import { useHead } from "@vueuse/head";
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

const EventMarkerMap = defineAsyncComponent(
  () => import("@/components/Search/EventMarkerMap.vue")
);

const search = useRouteQuery("search", "");
const searchDebounced = refDebounced(search, 1000);
const locationName = useRouteQuery("locationName", null);
const location = ref<IAddress | null>(null);

watch(location, (newLocation) => {
  console.debug("location change", newLocation);
  if (newLocation?.geom) {
    latitude.value = parseFloat(newLocation?.geom.split(";")[1]);
    longitude.value = parseFloat(newLocation?.geom.split(";")[0]);
    locationName.value = newLocation?.description;
    console.debug("set location", [
      latitude.value,
      longitude.value,
      locationName.value,
    ]);
  } else {
    console.debug("location emptied");
    latitude.value = undefined;
    longitude.value = undefined;
    locationName.value = null;
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
  MATCH_DESC = "MATCH_DESC",
  START_TIME_DESC = "START_TIME_DESC",
  CREATED_AT_DESC = "CREATED_AT_DESC",
  CREATED_AT_ASC = "CREATED_AT_ASC",
  PARTICIPANT_COUNT_DESC = "PARTICIPANT_COUNT_DESC",
}

enum GroupSortValues {
  MATCH_DESC = "MATCH_DESC",
  MEMBER_COUNT_DESC = "MEMBER_COUNT_DESC",
}

enum SortValues {
  MATCH_DESC = "MATCH_DESC",
  START_TIME_DESC = "START_TIME_DESC",
  CREATED_AT_DESC = "CREATED_AT_DESC",
  CREATED_AT_ASC = "CREATED_AT_ASC",
  PARTICIPANT_COUNT_DESC = "PARTICIPANT_COUNT_DESC",
  MEMBER_COUNT_DESC = "MEMBER_COUNT_DESC",
}

const arrayTransformer: RouteQueryTransformer<string[]> = {
  fromQuery(query: string) {
    return query.split(",");
  },
  toQuery(value: string[]) {
    return value.join(",");
  },
};

const eventPage = useRouteQuery("eventPage", 1, integerTransformer);
const groupPage = useRouteQuery("groupPage", 1, integerTransformer);

const latitude = useRouteQuery("lat", undefined, floatTransformer);
const longitude = useRouteQuery("lon", undefined, floatTransformer);

const distance = useRouteQuery("distance", "10_km");
const when = useRouteQuery("when", "any");
const contentType = useRouteQuery(
  "contentType",
  ContentType.ALL,
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
const sortBy = useRouteQuery(
  "sortBy",
  SortValues.MATCH_DESC,
  enumTransformer(SortValues)
);
const bbox = useRouteQuery("bbox", undefined);
const zoom = useRouteQuery("zoom", undefined, integerTransformer);

const EVENT_PAGE_LIMIT = 16;

const GROUP_PAGE_LIMIT = 16;

const props = defineProps<{
  tag?: string;
}>();

const { features } = useFeatures();
const { eventCategories } = useEventCategories();

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

const contentTypeMapping = computed(() => {
  return [
    {
      contentType: "ALL",
      label: t("Everything"),
    },
    {
      contentType: "EVENTS",
      label: t("Events"),
    },
    {
      contentType: "GROUPS",
      label: t("Groups"),
    },
  ];
});

const eventDistance = computed(() => {
  return [
    {
      id: "anywhere",
      label: t("Any distance"),
    },
    {
      id: "5_km",
      label: t(
        "{number} kilometers",
        {
          number: 5,
        },
        5
      ),
    },
    {
      id: "10_km",
      label: t(
        "{number} kilometers",
        {
          number: 10,
        },
        10
      ),
    },
    {
      id: "25_km",
      label: t(
        "{number} kilometers",
        {
          number: 25,
        },
        25
      ),
    },
    {
      id: "50_km",
      label: t(
        "{number} kilometers",
        {
          number: 50,
        },
        50
      ),
    },
    {
      id: "100_km",
      label: t(
        "{number} kilometers",
        {
          number: 100,
        },
        100
      ),
    },
    {
      id: "150_km",
      label: t(
        "{number} kilometers",
        {
          number: 150,
        },
        150
      ),
    },
  ];
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

const radius = computed(() => Number.parseInt(distance.value.slice(0, -3)));

const totalCount = computed(() => {
  return (searchEvents.value?.total ?? 0) + (searchGroups.value?.total ?? 0);
});

const sortOptions = computed(() => {
  const options = [
    {
      key: SortValues.MATCH_DESC,
      label: t("Best match"),
    },
  ];

  if (contentType.value == ContentType.EVENTS) {
    options.push(
      {
        key: SortValues.START_TIME_DESC,
        label: t("Event date"),
      },
      {
        key: SortValues.CREATED_AT_DESC,
        label: t("Most recently published"),
      },
      {
        key: SortValues.CREATED_AT_ASC,
        label: t("Least recently published"),
      },
      {
        key: SortValues.PARTICIPANT_COUNT_DESC,
        label: t("With the most participants"),
      }
    );
  }

  if (contentType.value == ContentType.GROUPS) {
    options.push({
      key: SortValues.MEMBER_COUNT_DESC,
      label: t("Number of members"),
    });
  }

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
    searchTarget.value = SearchTargets.GLOBAL;
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
  value: SortValues,
  allowed: typeof EventSortValues | typeof GroupSortValues
): SortValues | undefined => {
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

const { result: searchElementsResult, loading: searchLoading } = useQuery<{
  searchEvents: Paginate<TypeNamed<IEvent>>;
  searchGroups: Paginate<TypeNamed<IGroup>>;
}>(SEARCH_EVENTS_AND_GROUPS, () => ({
  term: searchDebounced.value,
  tags: props.tag,
  location: geoHashLocation.value,
  beginsOn: start.value,
  endsOn: end.value,
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
  sortByEvents: sortByForType(sortBy.value, EventSortValues),
  sortByGroups: sortByForType(sortBy.value, GroupSortValues),
  boostLanguages: boostLanguagesQuery.value,
}));
</script>
