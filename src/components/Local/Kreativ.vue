<template>
<close-content
  class="container mx-auto px-2"
  v-show="loading || (events && events.total > 0)"
  v-on="attrs"
>
	<template #title>
		{{ t("Kreative Events") }}
	</template>
    <template #content>
      <skeleton-event-result
        v-for="i in 6"
        class="scroll-ml-6 snap-center shrink-0 w-[18rem] my-4"
        :key="i"
        v-show="loading"
      />
      <event-card
        v-for="event in events.elements"
        :event="event"
        :key="event.uuid"
      />
      <more-content
        v-if="$route.query.lat && $route.query.lon"
        :to="{
          name: RouteName.SEARCH,
	query: {
		lat: $route.query.lat,
		lon: $route.query.lon,
		contentType: 'EVENTS',
		distance: `${$route.query.distance}_km`,
                categoryOneOf: 'KREATIV'
	},
        }"
      >
        {{
          t("View more events")
        }}
      </more-content>
    </template>
  </close-content>
</template>

<script lang="ts" setup>
import { LocationType } from "../../types/user-location.model";
import MoreContent from "./MoreContent.vue";
import CloseContent from "./CloseContent.vue";
import { computed, onMounted, useAttrs } from "vue";
import { SEARCH_EVENTS_AND_GROUPS } from "@/graphql/search";
import { IEvent } from "@/types/event.model";
import { useLazyQuery } from "@vue/apollo-composable";
import EventCard from "../Event/EventCard.vue";
import { Paginate } from "@/types/paginate";
import SkeletonEventResult from "../Event/SkeletonEventResult.vue";
import { useI18n } from "vue-i18n";
import { coordsToGeoHash } from "@/utils/location";
import { roundToNearestMinute } from "@/utils/datetime";
import RouteName from "@/router/name";
import { useRoute } from 'vue-router';

const route = useRoute();

// Lesen Sie die URL-Parameter und wandeln Sie sie in Zahlen um
const lat = parseFloat(route.query.lat);
const lon = parseFloat(route.query.lon);
const distance = parseFloat(route.query.distance);

const props = defineProps<{
  userLocation: LocationType;
  doingGeoloc?: boolean;
}>();
const emit = defineEmits(["doGeoLoc"]);

const EVENT_PAGE_LIMIT = 12;

const { t } = useI18n({ useScope: "global" });
const attrs = useAttrs();

const geoHash = computed(() => coordsToGeoHash(lat, lon));
const userLocationName = computed(() => {
  return props.userLocation?.name;
});

const now = computed(() => roundToNearestMinute(new Date()));

const searchEnabled = computed(() => geoHash.value != undefined);

const {
  result: eventsResult,
  loading: loadingEvents,
  load: load,
} = useLazyQuery<{
  searchEvents: Paginate<IEvent>;
}>(
  SEARCH_EVENTS_AND_GROUPS,
  () => ({
    location: geoHash.value,
    categoryOneOf: ["KREATIV"], 
    beginsOn: now.value,
    endsOn: undefined,
    radius: distance.value,
    eventPage: 1,
    limit: EVENT_PAGE_LIMIT,
    sortByEvents: "START_TIME_ASC",
  }),
  () => ({
    enabled: searchEnabled.value,
    fetchPolicy: "cache-first",
  })
);

const events = computed(
  () => eventsResult.value?.searchEvents ?? { elements: [], total: 0 }
);

onMounted(async () => {
  await load();
});

const loading = computed(() => props.doingGeoloc || loadingEvents.value);
</script>
