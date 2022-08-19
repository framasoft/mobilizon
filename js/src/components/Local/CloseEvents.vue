<template>
  <close-content
    v-show="loadingEvents || (events && events.total > 0)"
    :suggestGeoloc="suggestGeoloc"
    v-on="attrs"
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
        v-if="
          userLocation &&
          userLocationName &&
          userLocation.lat &&
          userLocation.lon &&
          userLocation.picture
        "
        :to="{
          name: 'SEARCH',
          query: {
            locationName: userLocationName,
            lat: userLocation.lat?.toString(),
            lon: userLocation.lon?.toString(),
            contentType: 'EVENTS',
            distance: '25',
          },
        }"
        :picture="userLocation.picture"
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
import { CURRENT_USER_LOCATION_CLIENT } from "@/graphql/location";
import { ICurrentUser, IUser } from "@/types/current-user.model";
import { CURRENT_USER_CLIENT, USER_SETTINGS } from "@/graphql/user";
import { coordsToGeoHash, geoHashToCoords } from "@/utils/location";
import { REVERSE_GEOCODE } from "@/graphql/address";
import { IAddress } from "@/types/address.model";
import { CONFIG } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { useI18n } from "vue-i18n";

const EVENT_PAGE_LIMIT = 12;

const { result: currentUserResult } = useQuery<{
  currentUser: ICurrentUser;
}>(CURRENT_USER_CLIENT);

const currentUser = computed(() => currentUserResult.value?.currentUser);

const { result: userResult } = useQuery<{ loggedUser: IUser }>(
  USER_SETTINGS,
  {},
  () => ({
    enabled: currentUser.value?.isLoggedIn,
  })
);

const loggedUser = computed(() => userResult.value?.loggedUser);

const { result: configResult } = useQuery<{ config: IConfig }>(CONFIG);

const config = computed<IConfig | undefined>(() => configResult.value?.config);

const serverLocation = computed(() => config.value?.location);

const { t } = useI18n({ useScope: "global" });
const attrs = useAttrs();

const coords = computed(() => {
  const userSettingsGeoHash =
    loggedUser.value?.settings?.location?.geohash ?? undefined;
  const userSettingsCoords = geoHashToCoords(userSettingsGeoHash);

  if (userSettingsCoords) {
    return { ...userSettingsCoords, isIPLocation: false };
  }

  return { ...serverLocation.value, isIPLocation: true };
});

const { result: reverseGeocodeResult } = useQuery<{
  reverseGeocode: IAddress[];
}>(REVERSE_GEOCODE, coords, () => ({
  enabled: coords.value?.longitude != undefined,
}));

const userSettingsLocation = computed(() => {
  const address = reverseGeocodeResult.value?.reverseGeocode[0];
  const placeName = address?.locality ?? address?.region ?? address?.country;
  return {
    lat: coords.value?.latitude,
    lon: coords.value?.longitude,
    name: placeName,
    picture: address?.pictureInfo,
    isIPLocation: coords.value?.isIPLocation,
  };
});

const { result: currentUserLocationResult } = useQuery<{
  currentUserLocation: LocationType;
}>(CURRENT_USER_LOCATION_CLIENT);
const currentUserLocation = computed(() => {
  return {
    ...currentUserLocationResult.value?.currentUserLocation,
    isIPLocation: false,
  };
});

const geohash = computed(() => {
  return coordsToGeoHash(userLocation.value?.lat, userLocation.value?.lon);
});

const userLocationName = computed(() => {
  return userLocation.value?.name;
});

const userLocation = computed(() => {
  if (
    !userSettingsLocation.value ||
    (userSettingsLocation.value?.isIPLocation &&
      currentUserLocation.value?.name)
  ) {
    return currentUserLocation.value;
  }
  return userSettingsLocation.value;
});

const suggestGeoloc = computed(() => userLocation.value?.isIPLocation);

const { result: eventsResult, loading: loadingEvents } = useQuery<{
  searchEvents: Paginate<IEvent>;
}>(SEARCH_EVENTS, {
  location: geohash,
  beginsOn: new Date(),
  endsOn: undefined,
  radius: 25,
  eventPage: 1,
  limit: EVENT_PAGE_LIMIT,
  type: "IN_PERSON",
});

const events = computed(
  () => eventsResult.value?.searchEvents ?? { elements: [], total: 0 }
);
</script>
