<template>
  <div>
    <!-- <o-loading v-model:active="$apollo.loading" /> -->
    <section
      class="mt-5 sm:mt-24"
      v-if="
        config &&
        (!currentUser || !currentUser.id || !currentActor || !currentActor.id)
      "
    >
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
    <unlogged-introduction />
    <search-fields v-model:search="search" v-model:location="location" />
    <categories-preview />
    <div
      id="recent_events"
      class="container mx-auto section"
      v-if="config && (!currentUser || !currentActor)"
    >
      <section class="events-recent">
        <h2 class="title">
          {{ $t("Last published events") }}
        </h2>
        <p>
          <i18n-t
            tag="span"
            keypath="On {instance} and other federated instances"
          >
            <template v-slot:instance>
              <b>{{ config.name }}</b>
            </template>
          </i18n-t>
        </p>
        <div v-if="events.total > 0">
          <multi-card :events="events.elements.slice(0, 6)" />
          <span
            class="block mt-2 text-right underline text-slate-700 dark:text-slate-300"
          >
            <router-link
              :to="{ name: RouteName.SEARCH }"
              class="hover:text-slate-800 hover:dark:text-slate-400"
              >{{ $t("View everything") }} >></router-link
            >
          </span>
        </div>
        <o-notification v-else variant="danger">{{
          $t("No events found")
        }}</o-notification>
      </section>
    </div>
    <div
      id="picture"
      v-if="config && (!currentUser || !currentUser.isLoggedIn)"
    >
      <div class="container mx-auto">
        <close-events @doGeoLoc="performGeoLocation()" />
      </div>
      <div class="picture-container">
        <picture>
          <source
            media="(max-width: 799px)"
            :srcset="`/img/pics/homepage-480w.webp`"
            type="image/webp"
          />

          <source
            media="(max-width: 1024px)"
            :srcset="`/img/pics/homepage-1024w.webp`"
            type="image/webp"
          />

          <source
            media="(max-width: 1920px)"
            :srcset="`/img/pics/homepage-1920w.webp`"
            type="image/webp"
          />

          <source
            media="(min-width: 1921px)"
            :srcset="`/img/pics/homepage.webp`"
            type="image/webp"
          />

          <img
            :src="`/img/pics/homepage-1024w.jpg`"
            width="3840"
            height="2719"
            alt=""
            loading="lazy"
          />
        </picture>
      </div>
      <presentation />
    </div>
    <div class="container mx-auto" v-if="config && loggedUserSettings">
      <section
        v-if="
          currentActor && currentActor.id && (welcomeBack || newRegisteredUser)
        "
      >
        <o-notification variant="info" v-if="welcomeBack">{{
          $t("Welcome back {username}!", {
            username: currentActor.displayName(),
          })
        }}</o-notification>
        <o-notification variant="info" v-if="newRegisteredUser">{{
          $t("Welcome to Mobilizon, {username}!", {
            username: currentActor.displayName(),
          })
        }}</o-notification>
      </section>
      <!-- Your upcoming events -->
      <section v-if="canShowMyUpcomingEvents">
        <h2 class="dark:text-white text-2xl font-bold">
          {{ $t("Your upcoming events") }}
        </h2>
        <div
          v-for="row of goingToEvents"
          class="text-slate-700 dark:text-slate-300"
          :key="row[0]"
        >
          <p
            class="date-component-container"
            v-if="isInLessThanSevenDays(row[0])"
          >
            <span v-if="isToday(row[0])">{{
              $tc("You have one event today.", row[1].size, {
                count: row[1].size,
              })
            }}</span>
            <span v-else-if="isTomorrow(row[0])">{{
              $tc("You have one event tomorrow.", row[1].size, {
                count: row[1].size,
              })
            }}</span>
            <span v-else-if="isInLessThanSevenDays(row[0])">
              {{
                $tc("You have one event in {days} days.", row[1].size, {
                  count: row[1].size,
                  days: calculateDiffDays(row[0]),
                })
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
            >{{ $t("View everything") }} >></router-link
          >
        </span>
      </section>
      <hr
        role="presentation"
        class="home-separator"
        v-if="canShowMyUpcomingEvents && canShowFollowedGroupEvents"
      />
      <!-- Events from your followed groups -->
      <section class="followActivity" v-if="canShowFollowedGroupEvents">
        <h2 class="title">
          {{ $t("Upcoming events from your groups") }}
        </h2>
        <p>{{ $t("That you follow or of which you are a member") }}</p>
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
            >{{ $t("View everything") }} >></router-link
          >
        </span>
      </section>
      <hr
        role="presentation"
        class="home-separator"
        v-if="canShowFollowedGroupEvents"
      />

      <!-- Events close to you -->
      <!-- <section class="events-close" v-if="canShowCloseEvents && radius">
        <h2 class="title">
          {{ $t("Events nearby") }}
        </h2>
        <p>
          {{
            $tc("Within {number} kilometers of {place}", radius, {
              radius,
              place: locationName,
            })
          }}
          <router-link
            :to="{ name: RouteName.PREFERENCES }"
            :title="$t('Change')"
          >
            <o-icon class="clickable" icon="pencil" size="small" />
          </router-link>
        </p>
        <multi-card :events="closeEvents.elements.slice(0, 4)" />
      </section> -->
      <hr
        role="presentation"
        class="home-separator"
        v-if="canShowMyUpcomingEvents"
      />
      <section class="events-recent">
        <h2 class="dark:text-white text-2xl font-bold">
          {{ $t("Last published events") }}
        </h2>
        <p class="mb-3">
          <i18n-t
            class="text-slate-700 dark:text-slate-300"
            tag="span"
            keypath="On {instance} and other federated instances"
          >
            <template v-slot:instance>
              <b>{{ config.name }}</b>
            </template>
          </i18n-t>
        </p>

        <div v-if="events && events.total > 0">
          <multi-card :events="events.elements.slice(0, 8)" />
          <span
            class="block mt-2 text-right underline text-slate-700 dark:text-slate-300"
          >
            <router-link
              :to="{ name: RouteName.SEARCH }"
              class="hover:text-slate-800 hover:dark:text-slate-400"
              >{{ $t("View everything") }} >></router-link
            >
          </span>
        </div>
        <o-notification v-else variant="danger"
          >{{ $t("No events found") }}<br />
          <div v-if="goingToEvents.size > 0">
            <!-- <o-icon size="small" icon="information-outline" /> -->
            <small>{{
              $t("The events you created are not shown here.")
            }}</small>
          </div>
        </o-notification>
      </section>
      <close-events @doGeoLoc="performGeoLocation()" />
    </div>
  </div>
</template>

<script lang="ts" setup>
import { EventSortField, ParticipantRole, SortDirection } from "@/types/enums";
import { Paginate } from "@/types/paginate";
import { IParticipant } from "../types/participant.model";
import { FETCH_EVENTS } from "../graphql/event";
import EventParticipationCard from "../components/Event/EventParticipationCard.vue";
import MultiCard from "../components/Event/MultiCard.vue";
import { CURRENT_ACTOR_CLIENT } from "../graphql/actor";
import { IPerson, Person } from "../types/actor";
import ngeohash from "ngeohash";
import {
  ICurrentUser,
  IUser,
  IUserSettings,
} from "../types/current-user.model";
import { CURRENT_USER_CLIENT } from "../graphql/user";
import { HOME_USER_QUERIES } from "../graphql/home";
import RouteName from "../router/name";
import { IEvent } from "../types/event.model";
import { CONFIG } from "../graphql/config";
import { IConfig } from "../types/config.model";
// import { IFollowedGroupEvent } from "../types/followedGroupEvent.model";
import CloseEvents from "@/components/Local/CloseEvents.vue";
import { computed, onMounted, reactive, watch } from "vue";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { useRouter } from "vue-router";
import { REVERSE_GEOCODE } from "@/graphql/address";
import { IAddress } from "@/types/address.model";
import {
  CURRENT_USER_LOCATION_CLIENT,
  UPDATE_CURRENT_USER_LOCATION_CLIENT,
} from "@/graphql/location";
import { LocationType } from "@/types/user-location.model";
import Presentation from "@/components/Home/MobilizonPresentation.vue";
import CategoriesPreview from "@/components/Home/CategoriesPreview.vue";
import UnloggedIntroduction from "@/components/Home/UnloggedIntroduction.vue";
import SearchFields from "@/components/Home/SearchFields.vue";
import { useHead } from "@vueuse/head";

const { result: resultEvents } = useQuery<{ events: Paginate<IEvent> }>(
  FETCH_EVENTS,
  {
    orderBy: EventSortField.INSERTED_AT,
    direction: SortDirection.DESC,
  }
);
const events = computed(
  () => resultEvents.value?.events || { total: 0, elements: [] }
);

const { result: currentActorResult } = useQuery<{ currentActor: IPerson }>(
  CURRENT_ACTOR_CLIENT
);
const currentActor = computed<Person | undefined>(
  () => new Person(currentActorResult.value?.currentActor)
);

const { result: currentUserResult } = useQuery<{
  currentUser: ICurrentUser;
}>(CURRENT_USER_CLIENT);

const currentUser = computed(() => currentUserResult.value?.currentUser);

const { result: configResult } = useQuery<{ config: IConfig }>(CONFIG);

const config = computed<IConfig | undefined>(() => configResult.value?.config);

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

const userSettingsLocation = computed(
  () => loggedUser.value?.settings?.location
);

const { result: currentUserLocationResult } = useQuery<{
  currentUserLocation: LocationType;
}>(CURRENT_USER_LOCATION_CLIENT);

const currentUserLocation = computed(() => {
  return currentUserLocationResult.value?.currentUserLocation;
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
  console.debug("geoLocationInformation", result.data);
  const placeName =
    geoLocationInformation.locality ??
    geoLocationInformation.region ??
    geoLocationInformation.country;
  console.log("place name", placeName);

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
}: GeolocationPosition) => {
  console.debug(
    "data found from navigator geocoding",
    latitude,
    longitude,
    accuracy
  );
  reverseGeoCodeInformation.latitude = latitude;
  reverseGeoCodeInformation.longitude = longitude;
  reverseGeoCodeInformation.accuracy = accuracy;
};

const performGeoLocation = () => {
  navigator.geolocation.getCurrentPosition(fetchAndSaveCurrentLocationName);
};

const GEOHASH_DEPTH = 9; // put enough accuracy, radius will be used anyway

const geohash = computed(
  () => userSettingsLocation.value?.geohash ?? currentUserLocationGeoHash
);

const currentUserLocationGeoHash = computed(() => {
  if (currentUserLocation.value?.lat && currentUserLocation.value?.lon) {
    return ngeohash.encode(
      currentUserLocation.value?.lat,
      currentUserLocation.value?.lon,
      GEOHASH_DEPTH
    );
  }
  return undefined;
});

const radius = computed(
  () => userSettingsLocation.value?.range ?? currentUserLocation.value?.accuracy
);
const locationName = computed(
  () => userSettingsLocation.value?.name ?? currentUserLocation.value?.name
);

// const { result: closeEventsResult } = useQuery<{
//   searchEvents: Paginate<IEvent>;
// }>(
//   CLOSE_CONTENT,
//   { location: geohash, radius },
//   { enabled: geohash.value !== undefined }
// );

// const closeEvents = computed(
//   () => closeEventsResult.value?.searchEvents || { total: 0, elements: [] }
// );

const currentUserParticipations = computed(
  () => loggedUser.value?.participations.elements
);

const instanceName = computed((): string | undefined => config.value?.name);
const welcomeBack = computed<boolean>(
  () => window.localStorage.getItem("welcome-back") === "yes"
);

const newRegisteredUser = computed<boolean>(
  () => window.localStorage.getItem("new-registered-user") === "yes"
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

// const eventDeleted = (eventid: string): void => {
//   currentUserParticipations = currentUserParticipations?.filter(
//     (participation) => participation.event.id !== eventid
//   );
// }

// viewEvent(event: IEvent): void {
//   this.$router.push({ name: RouteName.EVENT, params: { uuid: event.uuid } });
// }

const loggedUserSettings = computed<IUserSettings | undefined>(() => {
  return loggedUser.value?.settings;
});

const canShowMyUpcomingEvents = computed<boolean>(() => {
  return currentActor.value?.id != undefined && goingToEvents.value.size > 0;
});

// const canShowCloseEvents = computed<boolean>(() => {
//   return (
//     loggedUser.value?.settings?.location != undefined &&
//     closeEvents.value != undefined &&
//     closeEvents.value?.total > 0
//   );
// });

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
    .slice(0, 4);
});

onMounted(() => {
  if (window.localStorage.getItem("welcome-back")) {
    window.localStorage.removeItem("welcome-back");
  }
  if (window.localStorage.getItem("new-registered-user")) {
    window.localStorage.removeItem("new-registered-user");
  }
});

const router = useRouter();

watch(loggedUser, (loggedUserValue) => {
  console.debug("Try to detect empty user settings", loggedUserValue);
  if (loggedUserValue?.id && loggedUserValue?.settings === null) {
    console.debug("No user settings, pushing to onboarding assistant");
    router.push({
      name: RouteName.WELCOME_SCREEN,
      params: { step: "1" },
    });
  }
});

// metaInfo() {
//   return {
//     // eslint-disable-next-line @typescript-eslint/ban-ts-comment
//     // @ts-ignore
//     title: this.instanceName,
//     titleTemplate: "%s | Mobilizon",
//   };
// },

useHead({
  title: computed(() => instanceName.value ?? ""),
});
</script>
