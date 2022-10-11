<template>
  <div class="address-autocomplete">
    <div class="">
      <o-field
        :label-for="id"
        expanded
        :message="fieldErrors"
        :type="{ 'is-danger': fieldErrors }"
        class="!-mt-2"
        :labelClass="labelClass"
      >
        <template #label>
          {{ actualLabel }}
          <span v-if="gettingLocation">{{ t("Getting location") }}</span>
        </template>
        <p class="control" v-if="canShowLocateMeButton">
          <o-loading
            :full-page="false"
            v-model:active="gettingLocation"
            :can-cancel="false"
            :container="mapMarker?.$el"
          />
          <o-button
            ref="mapMarker"
            icon-right="map-marker"
            @click="locateMe"
            :title="t('Use my location')"
          />
        </p>
        <o-autocomplete
          :data="addressData"
          v-model="queryText"
          :placeholder="placeholderWithDefault"
          :customFormatter="(elem: IAddress) => addressFullName(elem)"
          :loading="isFetching"
          :debounceTyping="debounceDelay"
          @typing="asyncData"
          :icon="canShowLocateMeButton ? null : 'map-marker'"
          expanded
          @select="updateSelected"
          :id="id"
          :disabled="disabled"
          dir="auto"
          class="!mt-0"
        >
          <template #default="{ option }">
            <p class="flex gap-1">
              <o-icon :icon="addressToPoiInfos(option).poiIcon.icon" />
              <b>{{ addressToPoiInfos(option).name }}</b>
            </p>
            <small>{{ addressToPoiInfos(option).alternativeName }}</small>
          </template>
          <template #empty>
            <span v-if="isFetching">{{ t("Searching…") }}</span>
            <div v-else-if="queryText.length >= 3" class="enabled">
              <span>{{
                t('No results for "{queryText}"', { queryText })
              }}</span>
              <span>{{
                t(
                  "You can try another search term or drag and drop the marker on the map",
                  {
                    queryText,
                  }
                )
              }}</span>
              <!--                        <p class="control" @click="openNewAddressModal">-->
              <!--                            <button type="button" class="button is-primary">{{ t('Add') }}</button>-->
              <!--                        </p>-->
            </div>
          </template>
        </o-autocomplete>
        <o-button
          :disabled="!queryText"
          @click="resetAddress"
          class="reset-area"
          icon-left="close"
          :title="t('Clear address field')"
        />
      </o-field>
      <div
        class="mt-2 p-2 rounded-lg shadow-md dark:bg-violet-3"
        v-if="!hideSelected && (selected?.originId || selected?.url)"
      >
        <div class="">
          <address-info
            :address="selected"
            :show-icon="true"
            :show-timezone="true"
            :user-timezone="userTimezone"
          />
        </div>
      </div>
    </div>
    <div class="map" v-if="!hideMap && selected && selected.geom">
      <map-leaflet
        :coords="selected.geom"
        :marker="{
          text: [
            addressToPoiInfos(selected).name,
            addressToPoiInfos(selected).alternativeName,
          ],
          icon: addressToPoiInfos(selected).poiIcon.icon,
        }"
        :updateDraggableMarkerCallback="reverseGeoCode"
        :options="{ zoom: mapDefaultZoom }"
        :readOnly="false"
      />
    </div>
  </div>
</template>
<script lang="ts" setup>
import { LatLng } from "leaflet";
import {
  Address,
  IAddress,
  addressFullName,
  addressToPoiInfos,
} from "../../types/address.model";
import AddressInfo from "../../components/Address/AddressInfo.vue";
import { computed, ref, watch, defineAsyncComponent } from "vue";
import { useI18n } from "vue-i18n";
import { useGeocodingAutocomplete } from "@/composition/apollo/config";
import { ADDRESS } from "@/graphql/address";
import { useReverseGeocode } from "@/composition/apollo/address";
import { useLazyQuery } from "@vue/apollo-composable";
import { AddressSearchType } from "@/types/enums";
const MapLeaflet = defineAsyncComponent(
  () => import("@/components/LeafletMap.vue")
);

const props = withDefaults(
  defineProps<{
    modelValue: IAddress | null;
    defaultText?: string | null;
    label?: string;
    labelClass?: string;
    userTimezone?: string;
    disabled?: boolean;
    hideMap?: boolean;
    hideSelected?: boolean;
    placeholder?: string;
    resultType?: AddressSearchType;
  }>(),
  {
    labelClass: "",
    defaultText: "",
    disabled: false,
    hideMap: false,
    hideSelected: false,
  }
);

// const addressModalActive = ref(false);

const componentId = 0;

const emit = defineEmits(["update:modelValue"]);

const gettingLocationError = ref<string | null>(null);
const gettingLocation = ref(false);
const mapDefaultZoom = ref(15);

const addressData = ref<IAddress[]>([]);

const selected = ref<IAddress | null>(null);

const isFetching = ref(false);

const mapMarker = ref();

const placeholderWithDefault = computed(
  () => props.placeholder ?? t("e.g. 10 Rue Jangot")
);

// created(): void {
//   componentId += 1;
// }

const id = computed((): string => {
  return `full-address-autocomplete-${componentId}`;
});

const modelValue = computed(() => props.modelValue);

watch(modelValue, () => {
  if (!modelValue.value) return;
  selected.value = modelValue.value;
});

const updateSelected = (option: IAddress): void => {
  if (option == null) return;
  selected.value = option;
  emit("update:modelValue", selected.value);
};

// const resetPopup = (): void => {
//   selected.value = new Address();
// };

// const openNewAddressModal = (): void => {
//   resetPopup();
//   addressModalActive.value = true;
// };

const checkCurrentPosition = (e: LatLng): boolean => {
  if (!selected.value?.geom) return false;
  const lat = parseFloat(selected.value?.geom.split(";")[1]);
  const lon = parseFloat(selected.value?.geom.split(";")[0]);

  return e.lat === lat && e.lng === lon;
};

const { t, locale } = useI18n({ useScope: "global" });

const actualLabel = computed((): string => {
  return props.label ?? t("Find an address");
});

// eslint-disable-next-line class-methods-use-this
const canShowLocateMeButton = computed((): boolean => {
  return window.isSecureContext;
});

const { geocodingAutocomplete } = useGeocodingAutocomplete();

const debounceDelay = computed(() =>
  geocodingAutocomplete.value === true ? 200 : 2000
);

const { onResult: onAddressSearchResult, load: searchAddress } = useLazyQuery<{
  searchAddress: IAddress[];
}>(ADDRESS);

onAddressSearchResult((result) => {
  if (result.loading) return;
  const { data } = result;
  console.debug("onAddressSearchResult", data.searchAddress);
  addressData.value = data.searchAddress;
  isFetching.value = false;
});

const searchQuery = ref("");

const asyncData = async (query: string): Promise<void> => {
  if (!query.length) {
    addressData.value = [];
    selected.value = new Address();
    return;
  }

  if (query.length < 3) {
    addressData.value = [];
    return;
  }

  isFetching.value = true;

  searchQuery.value = query;

  searchAddress(undefined, {
    query: searchQuery.value,
    locale: locale.value,
    type: props.resultType,
  });
};

const queryText = computed({
  get() {
    return (
      (selected.value ? addressFullName(selected.value) : props.defaultText) ??
      ""
    );
  },
  set(text) {
    if (text === "" && selected.value?.id) {
      console.debug("doing reset");
      resetAddress();
    }
  },
});

const resetAddress = (): void => {
  emit("update:modelValue", null);
  selected.value = new Address();
};

const locateMe = async (): Promise<void> => {
  gettingLocation.value = true;
  gettingLocationError.value = null;
  try {
    const location = await getLocation();
    mapDefaultZoom.value = 12;
    reverseGeoCode(
      new LatLng(location.coords.latitude, location.coords.longitude),
      12
    );
  } catch (e: any) {
    gettingLocationError.value = e.message;
  }
  gettingLocation.value = false;
};

const { onResult: onReverseGeocodeResult, load: loadReverseGeocode } =
  useReverseGeocode();

onReverseGeocodeResult((result) => {
  if (result.loading !== false) return;
  const { data } = result;
  addressData.value = data.reverseGeocode;

  if (addressData.value.length > 0) {
    const defaultAddress = addressData.value[0];
    selected.value = defaultAddress;
    emit("update:modelValue", selected.value);
  }
});

const reverseGeoCode = (e: LatLng, zoom: number) => {
  // If the position has been updated through autocomplete selection, no need to geocode it!
  if (checkCurrentPosition(e)) return;

  loadReverseGeocode(undefined, {
    latitude: e.lat,
    longitude: e.lng,
    zoom,
    locale: locale.value as string,
  });
};

// eslint-disable-next-line no-undef
const getLocation = async (): Promise<GeolocationPosition> => {
  let errorMessage = t("Failed to get location.");
  return new Promise((resolve, reject) => {
    if (!("geolocation" in navigator)) {
      reject(new Error(errorMessage as string));
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        resolve(pos);
      },
      (err) => {
        switch (err.code) {
          case GeolocationPositionError.PERMISSION_DENIED:
            errorMessage = t("The geolocation prompt was denied.");
            break;
          case GeolocationPositionError.POSITION_UNAVAILABLE:
            errorMessage = t("Your position was not available.");
            break;
          case GeolocationPositionError.TIMEOUT:
            errorMessage = t("Geolocation was not determined in time.");
            break;
          default:
            errorMessage = err.message;
        }
        reject(new Error(errorMessage as string));
      }
    );
  });
};

const fieldErrors = computed(() => {
  return gettingLocationError.value;
});
</script>
<style lang="scss">
.autocomplete {
  .dropdown-menu {
    z-index: 2000;
  }

  .dropdown-item.is-disabled {
    opacity: 1 !important;
    cursor: auto;
  }
}

.read-only {
  cursor: pointer;
}

.map {
  height: 400px;
  width: 100%;
}
</style>
