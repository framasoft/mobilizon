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
      v-model="address"
      :hide-map="true"
      :hide-selected="true"
      :default-text="addressDefaultText"
      labelClass="sr-only"
      :placeholder="t('e.g. Nantes, Berlin, Cork, …')"
      v-on:update:modelValue="modelValueUpdate"
    >
      <o-dropdown v-model="distance" position="bottom-right" v-if="distance">
        <template #trigger>
          <o-button :title="t('Select distance')">{{ distanceText }}</o-button>
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
  getAddressFromLocal,
  storeAddressInLocal,
} from "@/utils/location";
import { computed, defineAsyncComponent } from "vue";
import { useI18n } from "vue-i18n";
import { useRouter, useRoute } from "vue-router";
import RouteName from "@/router/name";

const FullAddressAutoComplete = defineAsyncComponent(
  () => import("@/components/Event/FullAddressAutoComplete.vue")
);

const props = defineProps<{
  address: IAddress | null;
  addressDefaultText?: string | null;
  search: string;
  distance: number | null;
  fromLocalStorage?: boolean | false;
}>();

const router = useRouter();
const route = useRoute();

const emit = defineEmits<{
  (event: "update:address", address: IAddress | null): void;
  (event: "update:search", newSearch: string): void;
  (event: "update:distance", newDistance: number): void;
  (event: "submit"): void;
}>();

const address = computed({
  get(): IAddress | null {
    console.debug("-- get address --", props);
    if (props.address) {
      return props.address;
    }
    if (props.fromLocalStorage) {
      return getAddressFromLocal();
    }
    return null;
  },
  set(newAddress: IAddress | null) {
    emit("update:address", newAddress);
    if (props.fromLocalStorage) {
      storeAddressInLocal(newAddress);
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

const distanceText = computed(() => {
  return distance.value + " km";
});

const distanceList = computed(() => {
  const distances = [];
  [5, 10, 25, 50, 100, 150].forEach((value) => {
    distances.push({
      distance: value,
      label: t(
        "{number} kilometers",
        {
          number: value,
        },
        value
      ),
    });
  });
  return distances;
});

console.debug("initial", distance.value, search.value, address.value);

const modelValueUpdate = (newaddress: IAddress | null) => {
  emit("update:address", newaddress);
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
  if (address.value) {
    const { lat, lon } = addressToLocation(address.value);
    search_query.locationName = address.value.locality ?? address.value.region;
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
