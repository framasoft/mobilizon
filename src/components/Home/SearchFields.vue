<template>
  <form
    id="search-anchor"
    class="container mx-auto my-3 px-2 flex flex-wrap flex-col sm:flex-row items-stretch gap-2 text-center justify-center dark:text-slate-100"
    role="search"
    @submit.prevent="submit"
  >
    <label class="sr-only" for="search_field_input">{{
      t("Keyword, event title, group name, etc.")
    }}</label>
    <o-input
      v-model="search"
      :placeholder="t('Keyword, event title, group name, etc.')"
      id="search_field_input"
      autofocus
      autocapitalize="off"
      autocomplete="off"
      autocorrect="off"
      maxlength="1024"
      expanded
    />
    <full-address-auto-complete
      :resultType="AddressSearchType.ADMINISTRATIVE"
      v-model="location"
      :hide-map="true"
      :hide-selected="true"
      :default-text="locationDefaultText"
      labelClass="sr-only"
      :placeholder="t('e.g. Nantes, Berlin, Cork, …')"
      v-on:update:modelValue="modelValueUpdate"
    >
      <o-dropdown v-model="distance" position="bottom-right" v-if="distance">
        <template #trigger>
          <o-button
            icon-left="map-marker-distance"
            :title="t('Select distance')"
          />
        </template>
        <o-dropdown-item
          v-for="distance_item in distanceList"
          :value="distance_item.distance"
          :label="distance_item.label"
          :key="distance_item.distance"
        />
      </o-dropdown>
    </full-address-auto-complete>
    <o-button native-type="submit" icon-left="magnify">
      <template v-if="search">{{ t("Go!") }}</template>
      <template v-else>{{ t("Explore!") }}</template>
    </o-button>
  </form>
</template>

<script lang="ts" setup>
import { IAddress } from "@/types/address.model";
import { AddressSearchType } from "@/types/enums";
import {
  addressToLocation,
  getLocationFromLocal,
  storeLocationInLocal,
} from "@/utils/location";
import { computed, defineAsyncComponent } from "vue";
import { useI18n } from "vue-i18n";
import { useRouter, useRoute } from "vue-router";
import RouteName from "@/router/name";

const FullAddressAutoComplete = defineAsyncComponent(
  () => import("@/components/Event/FullAddressAutoComplete.vue")
);

const props = defineProps<{
  location: IAddress | null;
  locationDefaultText?: string | null;
  search: string;
  distance: number | null;
  fromLocalStorage?: boolean | false;
}>();

const router = useRouter();
const route = useRoute();

const emit = defineEmits<{
  (event: "update:location", location: IAddress | null): void;
  (event: "update:search", newSearch: string): void;
  (event: "update:distance", newDistance: number): void;
  (event: "submit"): void;
}>();

const location = computed({
  get(): IAddress | null {
    if (props.location) {
      return props.location;
    }
    if (props.fromLocalStorage) {
      return getLocationFromLocal();
    }
    return null;
  },
  set(newLocation: IAddress | null) {
    emit("update:location", newLocation);
    if (props.fromLocalStorage) {
      storeLocationInLocal(newLocation);
    }
  },
});

const search = computed({
  get(): string {
    return props.search;
  },
  set(newSearch: string) {
    emit("update:search", newSearch);
  },
});

const distance = computed({
  get(): number {
    return props.distance;
  },
  set(newDistance: number) {
    emit("update:distance", newDistance);
  },
});

const distanceList = computed(() => {
  return [
    {
      distance: 5,
      label: t(
        "{number} kilometers",
        {
          number: 5,
        },
        5
      ),
    },
    {
      distance: 10,
      label: t(
        "{number} kilometers",
        {
          number: 10,
        },
        10
      ),
    },
    {
      distance: 25,
      label: t(
        "{number} kilometers",
        {
          number: 25,
        },
        25
      ),
    },
    {
      distance: 50,
      label: t(
        "{number} kilometers",
        {
          number: 50,
        },
        50
      ),
    },
    {
      distance: 100,
      label: t(
        "{number} kilometers",
        {
          number: 100,
        },
        100
      ),
    },
    {
      distance: 150,
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

console.debug("initial", distance.value, search.value, location.value);

const modelValueUpdate = (newlocation: IAddress | null) => {
  emit("update:location", newlocation);
};

const submit = () => {
  emit("submit");
  const search_query = {
    locationName: undefined,
    lat: undefined,
    lon: undefined,
    search: undefined,
    distance: undefined,
  };
  if (search.value != "") {
    search_query.search = search.value;
  }
  if (location.value) {
    const { lat, lon } = addressToLocation(location.value);
    search_query.locationName =
      location.value.locality ?? location.value.region;
    search_query.lat = lat;
    search_query.lon = lon;
    if (distance.value != null) {
      search_query.distance = distance.value.toString() + "_km";
    }
  }
  router.push({
    name: RouteName.SEARCH,
    query: {
      ...route.query,
      ...search_query,
    },
  });
};

const { t } = useI18n({ useScope: "global" });
</script>
<style scoped>
#search-anchor :deep(.o-input__wrapper) {
  flex: 1;
}
</style>
