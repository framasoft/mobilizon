<template>
  <div class="container mx-auto mb-4">
    <h1 class="">{{ $t("Explore") }}</h1>
    <section v-if="tag">
      <i18n-t keypath="Events tagged with {tag}">
        <template #tag>
          <b-tag variant="light">{{ $t("#{tag}", { tag }) }}</b-tag>
        </template>
      </i18n-t>
    </section>
    <section class="" v-else>
      <div class="">
        <form @submit.prevent="submit()">
          <o-field
            :label="$t('Key words')"
            label-for="search"
            class="text-black"
          >
            <o-input
              icon="Magnify"
              type="search"
              id="search"
              ref="autocompleteSearchInput"
              :modelValue="search"
              @modelValue:update="debouncedUpdateSearchQuery"
              dir="auto"
              :placeholder="
                $t('For instance: London, Taekwondo, Architecture…')
              "
            />
          </o-field>
          <full-address-auto-complete
            :label="$t('Location')"
            v-model="location"
            id="location"
            ref="aac"
            :placeholder="$t('For instance: London')"
            :hideMap="true"
            :hideSelected="true"
          />
          <o-field
            :label="$t('Radius')"
            label-for="radius"
            class="searchRadius"
          >
            <o-select expanded v-model="radius" id="radius">
              <option
                v-for="(radiusOption, index) in radiusOptions"
                :key="index"
                :value="radiusOption"
              >
                {{ radiusString(radiusOption) }}
              </option>
            </o-select>
          </o-field>
          <o-field :label="$t('Date')" label-for="date">
            <o-select
              expanded
              v-model="when"
              id="date"
              :disabled="activeTab !== 0"
            >
              <option
                v-for="(option, index) in dateOptions"
                :key="index"
                :value="index"
              >
                {{ option.label }}
              </option>
            </o-select>
          </o-field>
          <o-field
            expanded
            :label="$t('Type')"
            label-for="type"
            class="searchType"
          >
            <o-select
              expanded
              v-model="type"
              id="type"
              :disabled="activeTab !== 0"
            >
              <option :value="null">
                {{ $t("Any type") }}
              </option>
              <option :value="'ONLINE'">
                {{ $t("Online") }}
              </option>
              <option :value="'IN_PERSON'">
                {{ $t("In person") }}
              </option>
            </o-select>
          </o-field>
          <o-field
            v-if="config"
            expanded
            :label="$t('Category')"
            label-for="category"
            class="searchCategory"
          >
            <o-select
              expanded
              v-model="eventCategory"
              id="category"
              :disabled="activeTab !== 0"
            >
              <option :value="null">
                {{ $t("Any category") }}
              </option>
              <option
                :value="category.id"
                v-for="category in config.eventCategories"
                :key="category.id"
              >
                {{ category.label }}
              </option>
            </o-select>
          </o-field>
        </form>
      </div>
    </section>
    <section class="mt-4" v-if="!canSearchEvents && !canSearchGroups">
      <!-- <o-loading v-model:active="$apollo.loading"></o-loading> -->
      <h2>{{ $t("Featured events") }}</h2>
      <div v-if="events && events.elements.length > 0">
        <multi-card class="my-4" :events="events?.elements" />
        <div
          class="pagination"
          v-if="events && events.total > EVENT_PAGE_LIMIT"
        >
          <o-pagination
            :total="events.total"
            v-model="featuredEventPage"
            :per-page="EVENT_PAGE_LIMIT"
            :aria-next-label="$t('Next page')"
            :aria-previous-label="$t('Previous page')"
            :aria-page-label="$t('Page')"
            :aria-current-label="$t('Current page')"
          >
          </o-pagination>
        </div>
      </div>
      <o-notification
        v-else-if="
          events &&
          events.elements.length === 0 &&
          featuredEventsLoading === false
        "
        variant="info"
        >{{ $t("No events found") }}</o-notification
      >
    </section>
    <o-tabs v-else v-model="activeTab" type="is-boxed">
      <!-- <o-loading v-model:active="searchLoading"></o-loading> -->
      <o-tab-item :value="SearchTabs.EVENTS">
        <template #header>
          <Calendar />
          <span>
            {{ $t("Events") }}
            <b-tag rounded>{{ searchEvents?.total }}</b-tag>
          </span>
        </template>
        <div v-if="searchEvents && searchEvents.total > 0">
          <multi-card class="my-4" :events="searchEvents?.elements" />
          <div
            class="pagination"
            v-if="searchEvents && searchEvents?.total > EVENT_PAGE_LIMIT"
          >
            <o-pagination
              :total="searchEvents.total"
              v-model="eventPage"
              :per-page="EVENT_PAGE_LIMIT"
              :aria-next-label="$t('Next page')"
              :aria-previous-label="$t('Previous page')"
              :aria-page-label="$t('Page')"
              :aria-current-label="$t('Current page')"
            >
            </o-pagination>
          </div>
        </div>
        <o-notification v-else-if="searchLoading === false" variant="primary">
          <p>{{ $t("No events found") }}</p>
          <p v-if="searchIsUrl && !currentUser?.id">
            {{
              $t(
                "Only registered users may fetch remote events from their URL."
              )
            }}
          </p>
        </o-notification>
      </o-tab-item>
      <o-tab-item v-if="!tag" :value="SearchTabs.GROUPS">
        <template #header>
          <AccountMultiple />

          <span>
            {{ $t("Groups") }} <b-tag rounded>{{ searchGroups?.total }}</b-tag>
          </span>
        </template>
        <o-notification
          v-if="config && !config.features.groups"
          variant="danger"
        >
          {{ $t("Groups are not enabled on this instance.") }}
        </o-notification>
        <div v-else-if="searchGroups && searchGroups?.total > 0">
          <multi-group-card class="my-4" :groups="searchGroups?.elements" />
          <div class="pagination">
            <o-pagination
              :total="searchGroups?.total"
              v-model="groupPage"
              :per-page="GROUP_PAGE_LIMIT"
              :aria-next-label="$t('Next page')"
              :aria-previous-label="$t('Previous page')"
              :aria-page-label="$t('Page')"
              :aria-current-label="$t('Current page')"
            >
            </o-pagination>
          </div>
        </div>
        <o-notification v-else-if="searchLoading === false" variant="danger">
          {{ $t("No groups found") }}
        </o-notification>
      </o-tab-item>
    </o-tabs>
  </div>
</template>

<script lang="ts" setup>
import ngeohash, { GeographicPoint } from "ngeohash";
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
import { SearchTabs } from "@/types/enums";
import MultiCard from "../components/Event/MultiCard.vue";
import { FETCH_EVENTS } from "../graphql/event";
import { IEvent } from "../types/event.model";
import { IAddress, Address } from "../types/address.model";
import FullAddressAutoComplete from "../components/Event/FullAddressAutoComplete.vue";
import { SEARCH_EVENTS_AND_GROUPS } from "../graphql/search";
import { Paginate } from "../types/paginate";
import { IGroup } from "../types/actor";
import MultiGroupCard from "../components/Group/MultiGroupCard.vue";
import { CONFIG } from "../graphql/config";
import { REVERSE_GEOCODE } from "../graphql/address";
import debounce from "lodash/debounce";
import { CURRENT_USER_CLIENT } from "@/graphql/user";
import { ICurrentUser } from "@/types/current-user.model";
import { useQuery } from "@vue/apollo-composable";
import { computed, inject, onMounted, ref, reactive } from "vue";
import { useI18n } from "vue-i18n";
import {
  floatTransformer,
  integerTransformer,
  useRouteQuery,
} from "vue-use-route-query";
import { IConfig } from "@/types/config.model";
import Calendar from "vue-material-design-icons/Calendar.vue";
import AccountMultiple from "vue-material-design-icons/AccountMultiple.vue";
import { useHead } from "@vueuse/head";
import type { Locale } from "date-fns";

const search = useRouteQuery("search", "");

interface ISearchTimeOption {
  label: string;
  start?: Date | null;
  end?: Date | null;
}

const featuredEventPage = useRouteQuery(
  "featuredEventPage",
  1,
  integerTransformer
);
const eventPage = useRouteQuery("eventPage", 1, integerTransformer);
const groupPage = useRouteQuery("groupPage", 1, integerTransformer);
const activeTab = useRouteQuery(
  "searchType",
  SearchTabs.EVENTS,
  integerTransformer
);
const geohash = useRouteQuery("geohash", "");
const radius = useRouteQuery("radius", null, floatTransformer);
const when = useRouteQuery("when", "any");
const type = useRouteQuery("type", "");
const eventCategory = useRouteQuery("eventCategory", "any");

const EVENT_PAGE_LIMIT = 12;

const GROUP_PAGE_LIMIT = 12;

// const DEFAULT_RADIUS = 25; // value to set if radius is null but location set

const DEFAULT_ZOOM = 11; // zoom on a city

// const GEOHASH_DEPTH = 9; // put enough accuracy, radius will be used anyway

const props = defineProps<{
  tag?: string;
}>();

const { result: configResult } = useQuery<{ config: IConfig }>(CONFIG);

const config = computed(() => configResult.value?.config);

const searchEvents = computed(() => searchElementsResult.value?.searchEvents);
const searchGroups = computed(() => searchElementsResult.value?.searchGroups);

const { result: currentUserResult } = useQuery<{ currentUser: ICurrentUser }>(
  CURRENT_USER_CLIENT
);

const currentUser = computed(() => currentUserResult.value?.currentUser);

const { t, locale } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Explore events")),
});

const location = ref<IAddress>(new Address());

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
    end: new Date(),
  },
  today: {
    label: t("Today") as string,
    start: new Date(),
    end: endOfToday(),
  },
  tomorrow: {
    label: t("Tomorrow") as string,
    start: startOfDay(addDays(new Date(), 1)),
    end: endOfDay(addDays(new Date(), 1)),
  },
  weekend: {
    label: t("This weekend") as string,
    start: weekend.value.start,
    end: weekend.value.end,
  },
  week: {
    label: t("This week") as string,
    start: new Date(),
    end: endOfWeek(new Date(), { locale: dateFnsLocale }),
  },
  next_week: {
    label: t("Next week") as string,
    start: startOfWeek(addWeeks(new Date(), 1), {
      locale: dateFnsLocale,
    }),
    end: endOfWeek(addWeeks(new Date(), 1), { locale: dateFnsLocale }),
  },
  month: {
    label: t("This month") as string,
    start: new Date(),
    end: endOfMonth(new Date()),
  },
  next_month: {
    label: t("Next month") as string,
    start: startOfMonth(addMonths(new Date(), 1)),
    end: endOfMonth(addMonths(new Date(), 1)),
  },
  any: {
    label: t("Any day") as string,
    start: undefined,
    end: undefined,
  },
};

// $refs!: {
//   aac: FullAddressAutoComplete;
//   autocompleteSearchInput: any;
// };

onMounted(() => {
  prepareLocation(geohash.value);
});

const radiusString = (radiusValue: number | null): string => {
  if (radiusValue) {
    return t("{nb} km", { nb: radiusValue }, radiusValue) as string;
  }
  return t("any distance") as string;
};

const radiusOptions: (number | null)[] = [1, 5, 10, 25, 50, 100, 150, null];

const submit = (): void => {
  refetchSearchElements();
};

const updateSearchQuery = (searchQuery: string): void => {
  search.value = searchQuery;
};

const debouncedUpdateSearchQuery = debounce(updateSearchQuery, 500);

const prepareLocation = (value: string | undefined): void => {
  if (value !== undefined) {
    // decode
    const latlon = ngeohash.decode(value);
    // set location
    reverseGeoCode(latlon, DEFAULT_ZOOM);
  }
};

// const { onResult: onReverseGeocodeResult, load: loadReverseGeocode } =
//   useReverseGeocode();

const reverseGeoCode = async (
  e: GeographicPoint,
  zoom: number
): Promise<void> => {
  const { result: reverseGeocodeResult } = useQuery<{
    reverseGeocode: IAddress[];
  }>(REVERSE_GEOCODE, () => ({
    latitude: e.latitude,
    longitude: e.longitude,
    zoom,
    locale: locale.value,
  }));

  const addressData = computed(
    () => reverseGeocodeResult.value?.reverseGeocode
  );
  if (addressData.value && addressData.value.length > 0) {
    location.value = addressData.value[0];
  }
};

// const locchange = (e: IAddress): void => {
//   if (radius.value === undefined || radius.value === null) {
//     radius.value = DEFAULT_RADIUS;
//   }
//   if (e?.geom) {
//     const [lon, lat] = e.geom.split(";");
//     geohash.value = ngeohash.encode(lat, lon, GEOHASH_DEPTH);
//   } else {
//     geohash.value = "";
//   }
// };

const start = computed((): Date | undefined | null => {
  if (dateOptions[when.value]) {
    return dateOptions[when.value].start;
  }
  return undefined;
});

const end = computed((): Date | undefined | null => {
  if (dateOptions[when.value]) {
    return dateOptions[when.value].end;
  }
  return undefined;
});

const canSearchGroups = computed((): boolean => {
  return (
    stringExists(search.value) ||
    (stringExists(geohash.value) && valueExists(radius.value))
  );
});

const canSearchEvents = computed((): boolean => {
  return (
    stringExists(search.value) ||
    stringExists(props.tag) ||
    stringExists(type.value) ||
    (stringExists(geohash.value) && valueExists(radius.value)) ||
    valueExists(end.value)
  );
});

// helper functions for skip
const valueExists = (value: any): boolean => {
  return value !== undefined && value !== null;
};

const stringExists = (value: string | null | undefined): boolean => {
  return valueExists(value) && (value as string).length > 0;
};

const searchIsUrl = computed((): boolean => {
  let url;
  if (!search.value) return false;
  try {
    url = new URL(search.value);
  } catch (_) {
    return false;
  }

  return url.protocol === "http:" || url.protocol === "https:";
});

const { result: eventResult, loading: featuredEventsLoading } = useQuery<{
  events: Paginate<IEvent>;
}>(FETCH_EVENTS, () => ({
  page: featuredEventPage.value,
  limit: EVENT_PAGE_LIMIT,
}));

const events = computed(() => eventResult.value?.events);

const searchVariables = reactive({
  term: search,
  tags: props.tag,
  location: geohash,
  beginsOn: start,
  endsOn: end,
  radius: radius,
  eventPage: eventPage,
  groupPage: groupPage,
  limit: EVENT_PAGE_LIMIT,
  type: type.value === "" ? undefined : type,
  category: eventCategory,
});

const {
  result: searchElementsResult,
  refetch: refetchSearchElements,
  loading: searchLoading,
} = useQuery<{
  searchEvents: Paginate<IEvent>;
  searchGroups: Paginate<IGroup>;
}>(SEARCH_EVENTS_AND_GROUPS, searchVariables);
</script>
