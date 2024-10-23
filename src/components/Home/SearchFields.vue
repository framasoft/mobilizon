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
    />
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
  fromLocalStorage?: boolean | false;
}>();

const router = useRouter();
const route = useRoute();

const emit = defineEmits<{
  (event: "update:location", location: IAddress | null): void;
  (event: "update:search", newSearch: string): void;
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

const modelValueUpdate = (newlocation: IAddress | null) => {
  emit("update:location", newlocation);
};

const submit = () => {
  emit("submit");
  const { lat, lon } = addressToLocation(location.value);
  router.push({
    name: RouteName.SEARCH,
    query: {
      ...route.query,
      locationName: location.value?.locality ?? location.value?.region,
      lat,
      lon,
      search: search.value,
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
