<template>
  <close-content
    class="container mx-auto px-2"
    v-show="loading || (events && events.total > 0)"
    :suggestGeoloc="suggestGeoloc"
    v-on="attrs"
    @doGeoLoc="emit('doGeoLoc')"
    :doingGeoloc="doingGeoloc"
  >
    <template #title>
      <template v-if="userLocationName">
        {{ t("Events nearby {position}", { position: userLocationName }) }}
      </template>
      <template v-else>
        {{ t("Events close to you") }}
      </template>
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
        v-if="userLocationName && userLocation?.lat && userLocation?.lon"
        :to="{
          name: RouteName.SEARCH,
          query: {
            locationName: userLocationName,
            lat: userLocation.lat?.toString(),
            lon: userLocation.lon?.toString(),
            contentType: 'EVENTS',
            distance: `${distance}_km`,
          },
        }"
        :picture="userLocation?.picture"
      >
        {{
          t("View more events around {position}", {
            position: userLocationName,
          })
        }}
      </more-content>
    </template>
  </close-content>
</template>

<script lang="ts" setup>
import { LocationType } from "../../types/user-location.model";
import MoreContent from "./MoreContent.vue";
import CloseContent from "./CloseContent.vue";
import { computed, onMounted, ref, useAttrs } from "vue";
import { SEARCH_EVENTS } from "@/graphql/search";
import { IEvent } from "@/types/event.model";
import { useLazyQuery } from "@vue/apollo-composable";
import EventCard from "../Event/EventCard.vue";
import { Paginate } from "@/types/paginate";
import SkeletonEventResult from "../Event/SkeletonEventResult.vue";
import { useI18n } from "vue-i18n";
import { coordsToGeoHash } from "@/utils/location";
import { roundToNearestMinute } from "@/utils/datetime";
import RouteName from "@/router/name";

const props = defineProps<{
  userLocation: LocationType;
  doingGeoloc?: boolean;
}>();
const emit = defineEmits(["doGeoLoc"]);

const EVENT_PAGE_LIMIT = 12;

const { t } = useI18n({ useScope: "global" });
const attrs = useAttrs();

const userLocation = computed(() => props.userLocation);

const userLocationName = computed(() => {
  return userLocation.value?.name;
});
const suggestGeoloc = computed(() => userLocation.value?.isIPLocation);

const geoHash = computed(() =>
  coordsToGeoHash(props.userLocation.lat, props.userLocation.lon)
);

const distance = computed<number>(() => (suggestGeoloc.value ? 150 : 25));

const now = computed(() => roundToNearestMinute(new Date()));

const searchEnabled = computed(() => geoHash.value != undefined);
const enabled = ref(false);

const {
  result: eventsResult,
  loading: loadingEvents,
  load: load,
} = useLazyQuery<{
  searchEvents: Paginate<IEvent>;
}>(
  SEARCH_EVENTS,
  () => ({
    location: geoHash.value,
    beginsOn: now.value,
    endsOn: undefined,
    radius: distance.value,
    eventPage: 1,
    limit: EVENT_PAGE_LIMIT,
    type: "IN_PERSON",
  }),
  () => ({
    enabled: searchEnabled.value,
    fetchPolicy: "cache-first",
  })
);

const events = computed(
  () => eventsResult.value?.searchEvents ?? { elements: [], total: 0 }
);

onMounted(() => {
  load();
});

const loading = computed(() => props.doingGeoloc || loadingEvents.value);
</script>
