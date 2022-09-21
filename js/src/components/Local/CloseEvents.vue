<template>
  <close-content
    class="container mx-auto px-2"
    v-show="loadingEvents || (events && events.total > 0)"
    :suggestGeoloc="suggestGeoloc"
    v-on="attrs"
    @doGeoLoc="emit('doGeoLoc')"
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
        v-show="loadingEvents"
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
            distance: '25_km',
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
import { computed, useAttrs } from "vue";
import { SEARCH_EVENTS } from "@/graphql/search";
import { IEvent } from "@/types/event.model";
import { useQuery } from "@vue/apollo-composable";
import EventCard from "../Event/EventCard.vue";
import { Paginate } from "@/types/paginate";
import SkeletonEventResult from "../Event/SkeletonEventResult.vue";
import { useI18n } from "vue-i18n";
import { coordsToGeoHash } from "@/utils/location";
import { roundToNearestMinute } from "@/utils/datetime";
import RouteName from "@/router/name";

const props = defineProps<{ userLocation: LocationType }>();
const emit = defineEmits(["doGeoLoc"]);

const EVENT_PAGE_LIMIT = 12;

const { t } = useI18n({ useScope: "global" });
const attrs = useAttrs();

const userLocationName = computed(() => {
  return props.userLocation?.name;
});
const suggestGeoloc = computed(() => props.userLocation?.isIPLocation);

const geoHash = computed(() =>
  coordsToGeoHash(props.userLocation.lat, props.userLocation.lon)
);

const { result: eventsResult, loading: loadingEvents } = useQuery<{
  searchEvents: Paginate<IEvent>;
}>(
  SEARCH_EVENTS,
  () => ({
    location: geoHash.value,
    beginsOn: roundToNearestMinute(new Date()),
    endsOn: undefined,
    radius: 25,
    eventPage: 1,
    limit: EVENT_PAGE_LIMIT,
    type: "IN_PERSON",
  }),
  () => ({
    enabled: geoHash.value !== undefined,
  })
);

const events = computed(
  () => eventsResult.value?.searchEvents ?? { elements: [], total: 0 }
);
</script>
