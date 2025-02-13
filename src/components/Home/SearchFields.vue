<template>
  <form
    id="search-anchor"
    class="container mx-auto p-2 flex flex-col flex-wrap items-stretch gap-2 justify-center dark:text-slate-100"
    role="search"
    @submit.prevent="submit"
  >
    <div class="flex flex-col flex-wrap sm:flex-row gap-2 justify-center">
      <label class="sr-only" for="search_field_input">{{
        t("Keyword, event title, group name, etc.")
      }}</label>
      <o-input
        class="min-w-48"
        v-if="search != null"
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
          <template #trigger="{ active }">
            <o-button
              :title="t('Select distance')"
              :icon-right="active ? 'menu-up' : 'menu-down'"
            >
              {{ distanceText }}
            </o-button>
          </template>
          <o-dropdown-item
            v-for="distance_item in distanceList"
            :value="distance_item.distance"
            :label="distance_item.label"
            :key="distance_item.distance"
          />
        </o-dropdown>
      </full-address-auto-complete>
    </div>
    <div class="flex flex-col flex-wrap sm:flex-row gap-2 justify-center">
      <o-button
        :class="'search-Event min-w-40 ' + select_button_class('EVENTS')"
        native-type="submit"
        icon-left="calendar"
      >
        {{ t("Events") + number_result("EVENTS") }}
      </o-button>
      <o-button
        :class="'search-Activity min-w-40 ' + select_button_class('LONGEVENTS')"
        native-type="submit"
        icon-left="calendar-star"
        v-if="isLongEvents"
      >
        {{ t("Activities") + number_result("LONGEVENTS") }}
      </o-button>
      <o-button
        :class="'search-Group min-w-40 ' + select_button_class('GROUPS')"
        native-type="submit"
        icon-left="account-multiple"
      >
        {{ t("Groups") + number_result("GROUPS") }}
      </o-button>
    </div>
  </form>
</template>

<script lang="ts" setup>
import { IAddress } from "@/types/address.model";
import { AddressSearchType, ContentType } from "@/types/enums";
import {
  addressToLocation,
  getAddressFromLocal,
  storeAddressInLocal,
} from "@/utils/location";
import { computed, defineAsyncComponent } from "vue";
import { useI18n } from "vue-i18n";
import { useRouter, useRoute } from "vue-router";
import RouteName from "@/router/name";
import { useIsLongEvents } from "@/composition/apollo/config";

const FullAddressAutoComplete = defineAsyncComponent(
  () => import("@/components/Event/FullAddressAutoComplete.vue")
);

const props = defineProps<{
  address: IAddress | null;
  addressDefaultText?: string | null;
  search: string | null;
  distance: number | null;
  fromLocalStorage?: boolean | false;
  numberOfSearch: object | null;
}>();

const router = useRouter();
const route = useRoute();
const { isLongEvents } = useIsLongEvents();

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

const select_button_class = (current_content_type: string) => {
  if (route.query.contentType === undefined) {
    return "";
  } else {
    return current_content_type === route.query.contentType
      ? "active"
      : "disactive";
  }
};

const number_result = (current_content_type: string) => {
  console.log(">> number_result", props.numberOfSearch);
  if (props.numberOfSearch == undefined) {
    return "";
  }
  const nb_value = props.numberOfSearch[current_content_type];
  if (nb_value == undefined) {
    return "";
  }
  return " (" + nb_value.toString() + ")";
};

console.debug("initial", distance.value, search.value, address.value);

const modelValueUpdate = (newaddress: IAddress | null) => {
  emit("update:address", newaddress);
};

const submit = (event) => {
  emit("submit");
  const btn_classes = event.submitter.getAttribute("class").split(" ");
  const search_query = {
    locationName: undefined,
    lat: undefined,
    lon: undefined,
    search: undefined,
    distance: undefined,
    contentType: undefined,
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
  if (btn_classes.includes("search-Event")) {
    search_query.contentType = ContentType.EVENTS;
  }
  if (btn_classes.includes("search-Activity")) {
    search_query.contentType = ContentType.LONGEVENTS;
  }
  if (btn_classes.includes("search-Group")) {
    search_query.contentType = ContentType.GROUPS;
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
.active {
  text-decoration: underline;
  font-weight: bold;
}
.disactive {
  color: #eee;
  font-weight: 300;
}
</style>
