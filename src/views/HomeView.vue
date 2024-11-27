<template>
  <!-- <o-loading v-model:active="$apollo.loading" /> -->
  <!-- Nice looking SVGs -->
  <section class="mt-5 sm:mt-24">
    <div class="-z-10 overflow-hidden">
      <img
        alt=""
        src="/img/shape-1.svg"
        class="-z-10 absolute left-[2%] top-36"
        width="300"
      />
      <img
        alt=""
        src="/img/shape-2.svg"
        class="-z-10 absolute left-[50%] top-[5%] -translate-x-2/4 opacity-60"
        width="800"
      />
      <img
        alt=""
        src="/img/shape-3.svg"
        class="-z-10 absolute top-0 right-36"
        width="200"
      />
    </div>
  </section>
  <!-- Unlogged introduction -->
  <unlogged-introduction :config="config" v-if="config && !isLoggedIn" />
  <!-- Search fields -->
  <search-fields
    v-model:search="search"
    v-model:address="userAddress"
    v-model:distance="distance"
    v-on:update:address="updateAddress"
    :fromLocalStorage="true"
    :addressDefaultText="userLocation?.name"
    :key="increated"
  />
  <!-- Welcome back -->
  <section
    class="container mx-auto"
    v-if="currentActor?.id && (welcomeBack || newRegisteredUser)"
  >
    <o-notification variant="info" v-if="welcomeBack">{{
      t("Welcome back {username}!", {
        username: displayName(currentActor),
      })
    }}</o-notification>
    <o-notification variant="info" v-if="newRegisteredUser">{{
      t("Welcome to Mobilizon, {username}!", {
        username: displayName(currentActor),
      })
    }}</o-notification>
  </section>
  <!-- Your upcoming events -->
  <section v-if="canShowMyUpcomingEvents" class="container mx-auto">
    <h2 class="dark:text-white font-bold">
      {{ t("Your upcoming events") }}
    </h2>
    <div
      v-for="row of goingToEvents"
      class="text-slate-700 dark:text-slate-300"
      :key="row[0]"
    >
      <p class="date-component-container" v-if="isInLessThanSevenDays(row[0])">
        <span v-if="isToday(row[0])">{{
          t(
            "You have one event today.",
            {
              count: row[1].size,
            },
            row[1].size
          )
        }}</span>
        <span v-else-if="isTomorrow(row[0])">{{
          t(
            "You have one event tomorrow.",
            {
              count: row[1].size,
            },
            row[1].size
          )
        }}</span>
        <span v-else-if="isInLessThanSevenDays(row[0])">
          {{
            t(
              "You have one event in {days} days.",
              {
                count: row[1].size,
                days: calculateDiffDays(row[0]),
              },
              row[1].size
            )
          }}
        </span>
      </p>
      <div>
        <event-participation-card
          v-for="participation in thisWeek(row)"
          :key="participation[1].id"
          :participation="participation[1]"
        />
      </div>
    </div>
    <span
      class="block mt-2 text-right underline text-slate-700 dark:text-slate-300"
    >
      <router-link
        :to="{ name: RouteName.MY_EVENTS }"
        class="hover:text-slate-800 hover:dark:text-slate-400"
        >{{ t("View everything") }} >></router-link
      >
    </span>
  </section>
  <!-- Events from your followed groups -->
  <section
    class="relative pt-10 px-2 container mx-auto px-2"
    v-if="canShowFollowedGroupEvents"
  >
    <h2
      class="text-xl font-bold tracking-tight text-gray-900 dark:text-gray-100 mt-0"
    >
      {{ t("Upcoming events from your groups") }}
    </h2>
    <p>{{ t("That you follow or of which you are a member") }}</p>
    <multi-card :events="filteredFollowedGroupsEvents" />
    <span
      class="block mt-2 text-right underline text-slate-700 dark:text-slate-300"
    >
      <router-link
        class="hover:text-slate-800 hover:dark:text-slate-400"
        :to="{
          name: RouteName.MY_EVENTS,
          query: {
            showUpcoming: 'true',
            showDrafts: 'false',
            showAttending: 'false',
            showMyGroups: 'true',
          },
        }"
        >{{ t("View everything") }} >></router-link
      >
    </span>
  </section>
  <!-- Recent events -->
  <CloseEvents
    @doGeoLoc="performGeoLocation()"
    :userLocation="userLocation"
    :doingGeoloc="doingGeoloc"
    :distance="distance"
  />
</template>

<script lang="ts" setup>
import { ParticipantRole } from "@/types/enums";
import { IParticipant } from "../types/participant.model";
import MultiCard from "../components/Event/MultiCard.vue";
import { CURRENT_ACTOR_CLIENT } from "../graphql/actor";
import { IPerson, displayName } from "../types/actor";
import { ICurrentUser, IUser } from "../types/current-user.model";
import { CURRENT_USER_CLIENT } from "../graphql/user";
import { HOME_USER_QUERIES } from "../graphql/home";
import RouteName from "../router/name";
import { IEvent } from "../types/event.model";
// import { IFollowedGroupEvent } from "../types/followedGroupEvent.model";
import CloseEvents from "@/components/Local/CloseEvents.vue";
import {
  computed,
  onMounted,
  reactive,
  ref,
  watch,
  defineAsyncComponent,
} from "vue";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { useRouter } from "vue-router";
import { REVERSE_GEOCODE } from "@/graphql/address";
import { IAddress } from "@/types/address.model";
import {
  CURRENT_USER_LOCATION_CLIENT,
  UPDATE_CURRENT_USER_LOCATION_CLIENT,
} from "@/graphql/location";
import { LocationType } from "@/types/user-location.model";
import UnloggedIntroduction from "@/components/Home/UnloggedIntroduction.vue";
import SearchFields from "@/components/Home/SearchFields.vue";
import { useHead } from "@unhead/vue";
import {
  addressToLocation,
  geoHashToCoords,
  getAddressFromLocal,
  locationToAddress,
  storeAddressInLocal,
} from "@/utils/location";
import { useServerProvidedLocation } from "@/composition/apollo/config";
import { ABOUT } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { useI18n } from "vue-i18n";

const { t } = useI18n({ useScope: "global" });

const EventParticipationCard = defineAsyncComponent(
  () => import("@/components/Event/EventParticipationCard.vue")
);

const { result: aboutConfigResult } = useQuery<{
  config: Pick<
    IConfig,
    "name" | "description" | "slogan" | "registrationsOpen"
  >;
}>(ABOUT);

const config = computed(() => aboutConfigResult.value?.config);

const { result: currentActorResult } = useQuery<{ currentActor: IPerson }>(
  CURRENT_ACTOR_CLIENT
);
const currentActor = computed<IPerson | undefined>(
  () => currentActorResult.value?.currentActor
);

const { result: currentUserResult } = useQuery<{
  currentUser: ICurrentUser;
}>(CURRENT_USER_CLIENT);

const currentUser = computed(() => currentUserResult.value?.currentUser);

const instanceName = computed(() => config.value?.name);

const { result: userResult } = useQuery<{ loggedUser: IUser }>(
  HOME_USER_QUERIES,
  { afterDateTime: new Date().toISOString() },
  () => ({
    enabled: currentUser.value?.id != undefined,
  })
);

const loggedUser = computed(() => userResult.value?.loggedUser);
const followedGroupEvents = computed(
  () => userResult.value?.loggedUser?.followedGroupEvents
);

const currentUserParticipations = computed(
  () => loggedUser.value?.participations.elements
);

const increated = ref(0);
const address = ref(null);
const search = ref(null);
const noAddress = ref(false);
const current_distance = ref(null);

watch(address, (newAdd, oldAdd) =>
  console.debug("ADDRESS UPDATED from", { ...oldAdd }, " to ", { ...newAdd })
);

const isToday = (date: string): boolean => {
  return new Date(date).toDateString() === new Date().toDateString();
};

const isTomorrow = (date: string): boolean => {
  return isInDays(date, 1);
};

const isInDays = (date: string, nbDays: number): boolean => {
  return calculateDiffDays(date) === nbDays;
};

const isBefore = (date: string, nbDays: number): boolean => {
  return calculateDiffDays(date) < nbDays;
};

const isAfter = (date: string, nbDays: number): boolean => {
  return calculateDiffDays(date) >= nbDays;
};

const isInLessThanSevenDays = (date: string): boolean => {
  return isBefore(date, 7);
};

const thisWeek = (
  row: [string, Map<string, IParticipant>]
): Map<string, IParticipant> => {
  if (isInLessThanSevenDays(row[0])) {
    return row[1];
  }
  return new Map();
};

const calculateDiffDays = (date: string): number => {
  return Math.ceil(
    (new Date(date).getTime() - new Date().getTime()) / 1000 / 60 / 60 / 24
  );
};

const thisWeekGoingToEvents = computed<IParticipant[]>(() => {
  const res = (currentUserParticipations.value || []).filter(
    ({ event, role }) =>
      event.beginsOn != null &&
      isAfter(event.beginsOn, 0) &&
      isBefore(event.beginsOn, 7) &&
      role !== ParticipantRole.REJECTED
  );
  res.sort(
    (a: IParticipant, b: IParticipant) =>
      new Date(a.event.beginsOn).getTime() -
      new Date(b.event.beginsOn).getTime()
  );
  return res;
});

const goingToEvents = computed<Map<string, Map<string, IParticipant>>>(() => {
  return thisWeekGoingToEvents.value?.reduce(
    (
      acc: Map<string, Map<string, IParticipant>>,
      participation: IParticipant
    ) => {
      const day = new Date(participation.event.beginsOn).toDateString();
      const participations: Map<string, IParticipant> =
        acc.get(day) || new Map();
      participations.set(
        `${participation.event.uuid}${participation.actor.id}`,
        participation
      );
      acc.set(day, participations);
      return acc;
    },
    new Map()
  );
});

const canShowMyUpcomingEvents = computed<boolean>(() => {
  return currentActor.value?.id != undefined && goingToEvents.value.size > 0;
});

const canShowFollowedGroupEvents = computed<boolean>(() => {
  return filteredFollowedGroupsEvents.value.length > 0;
});

const filteredFollowedGroupsEvents = computed<IEvent[]>(() => {
  return (followedGroupEvents.value?.elements || [])
    .map(({ event }: { event: IEvent }) => event)
    .filter(
      ({ id }) =>
        !thisWeekGoingToEvents.value
          .map(({ event: { id: event_id } }) => event_id)
          .includes(id)
    )
    .slice(0, 93);
});

const welcomeBack = ref(false);
const newRegisteredUser = ref(false);

onMounted(() => {
  if (window.localStorage.getItem("welcome-back")) {
    welcomeBack.value = true;
    window.localStorage.removeItem("welcome-back");
  }
  if (window.localStorage.getItem("new-registered-user")) {
    newRegisteredUser.value = true;
    window.localStorage.removeItem("new-registered-user");
  }
});

const router = useRouter();

watch(loggedUser, (loggedUserValue) => {
  if (
    loggedUserValue?.id &&
    loggedUserValue?.settings === null &&
    loggedUserValue.defaultActor?.id
  ) {
    console.info("No user settings, going to onboarding", loggedUserValue);
    router.push({
      name: RouteName.WELCOME_SCREEN,
      params: { step: "1" },
    });
  }
});
const isLoggedIn = computed(() => loggedUser.value?.id !== undefined);

/**
 * Geolocation stuff
 */

// The location hash saved in the user settings (should be the default)
const userSettingsLocationGeoHash = computed(
  () => loggedUser.value?.settings?.location?.geohash
);

// The location provided by the server
const { location: serverLocation } = useServerProvidedLocation();

// The coords from the user location or the server provided location
const coords = computed(() => {
  const userSettingsCoords = geoHashToCoords(
    userSettingsLocationGeoHash.value ?? undefined
  );

  return { ...serverLocation.value, isIPLocation: !userSettingsCoords };
});

const { result: reverseGeocodeResult } = useQuery<{
  reverseGeocode: IAddress[];
}>(REVERSE_GEOCODE, coords, () => ({
  enabled: coords.value?.longitude != undefined,
}));

const userSettingsLocation = computed(() => {
  const location = reverseGeocodeResult.value?.reverseGeocode[0];
  const placeName = location?.locality ?? location?.region ?? location?.country;
  console.debug(
    "userSettingsLocation from reverseGeocode",
    reverseGeocodeResult.value,
    coords.value,
    placeName
  );
  if (placeName) {
    return {
      lat: coords.value?.latitude,
      lon: coords.value?.longitude,
      name: placeName,
      picture: location?.pictureInfo,
      isIPLocation: coords.value?.isIPLocation,
    };
  } else {
    return {};
  }
});

const { result: currentUserLocationResult } = useQuery<{
  currentUserLocation: LocationType;
}>(CURRENT_USER_LOCATION_CLIENT);

// The user's location currently in the Apollo cache
const currentUserLocation = computed(() => {
  console.debug(
    "currentUserLocation from LocationType",
    currentUserLocationResult.value
  );
  return {
    ...(currentUserLocationResult.value?.currentUserLocation ?? {
      lat: undefined,
      lon: undefined,
      accuracy: undefined,
      isIPLocation: undefined,
      name: undefined,
      picture: undefined,
    }),
    isIPLocation: false,
  };
});

const userLocation = computed(() => {
  console.debug("new userLocation");
  if (noAddress.value) {
    return {
      lon: null,
      lat: null,
      name: null,
    };
  }
  if (address.value) {
    console.debug("userLocation is typed location");
    return addressToLocation(address.value);
  }
  const local_address = getAddressFromLocal();
  if (local_address) {
    return addressToLocation(local_address);
  }
  if (
    !userSettingsLocation.value ||
    (userSettingsLocation.value?.isIPLocation &&
      currentUserLocation.value?.name)
  ) {
    return currentUserLocation.value;
  }
  return userSettingsLocation.value;
});

const userAddress = computed({
  get(): IAddress | null {
    if (noAddress.value) {
      return null;
    }
    if (address.value) {
      return address.value;
    }
    const local_address = getAddressFromLocal();
    if (local_address) {
      return local_address;
    }
    if (
      !userSettingsLocation.value ||
      (userSettingsLocation.value?.isIPLocation &&
        currentUserLocation.value?.name)
    ) {
      return locationToAddress(currentUserLocation.value);
    }
    return locationToAddress(userSettingsLocation.value);
  },
  set(newAddress: IAddress | null) {
    address.value = newAddress;
    noAddress.value = newAddress == null;
  },
});

const distance = computed({
  get(): number | null {
    if (noAddress.value || !userLocation.value?.name) {
      return null;
    } else if (current_distance.value == null) {
      return userLocation.value?.isIPLocation ? 150 : 25;
    }
    return current_distance.value;
  },
  set(newDistance: number) {
    current_distance.value = newDistance;
  },
});

const { mutate: saveCurrentUserLocation } = useMutation<any, LocationType>(
  UPDATE_CURRENT_USER_LOCATION_CLIENT
);

const reverseGeoCodeInformation = reactive<{
  latitude: number | undefined;
  longitude: number | undefined;
  accuracy: number | undefined;
}>({
  latitude: undefined,
  longitude: undefined,
  accuracy: undefined,
});

const { onResult: onReverseGeocodeResult } = useQuery<{
  reverseGeocode: IAddress[];
}>(REVERSE_GEOCODE, reverseGeoCodeInformation, () => ({
  enabled: reverseGeoCodeInformation.latitude !== undefined,
}));

onReverseGeocodeResult((result) => {
  if (!result?.data) return;
  const geoLocationInformation = result?.data?.reverseGeocode[0];
  const placeName =
    geoLocationInformation.locality ??
    geoLocationInformation.region ??
    geoLocationInformation.country;

  saveCurrentUserLocation({
    lat: reverseGeoCodeInformation.latitude,
    lon: reverseGeoCodeInformation.longitude,
    accuracy: Math.round(reverseGeoCodeInformation.accuracy ?? 12) / 1000,
    isIPLocation: false,
    name: placeName,
    picture: geoLocationInformation.pictureInfo,
  });
});

const fetchAndSaveCurrentLocationName = async ({
  coords: { latitude, longitude, accuracy },
}: // eslint-disable-next-line no-undef
GeolocationPosition) => {
  reverseGeoCodeInformation.latitude = latitude;
  reverseGeoCodeInformation.longitude = longitude;
  reverseGeoCodeInformation.accuracy = accuracy;
  doingGeoloc.value = false;
};

const doingGeoloc = ref(false);

const performGeoLocation = () => {
  doingGeoloc.value = true;
  navigator.geolocation.getCurrentPosition(
    fetchAndSaveCurrentLocationName,
    () => {
      doingGeoloc.value = false;
    }
  );
};

const updateAddress = (newAddress: IAddress | null) => {
  if (address.value?.geom != newAddress?.geom || newAddress == null) {
    increated.value += 1;
    storeAddressInLocal(newAddress);
  }
  address.value = newAddress;
  noAddress.value = newAddress == null;
};

/**
 * View Head
 */
useHead({
  title: computed(() => instanceName.value ?? ""),
});
</script>
