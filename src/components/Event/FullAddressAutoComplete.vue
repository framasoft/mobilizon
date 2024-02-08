<template>
  <div class="address-autocomplete">
    <div class="">
      <o-field
        :label-for="id"
        :message="fieldErrors"
        :variant="fieldErrors ? 'danger' : ''"
        class="!-mt-2"
        :labelClass="labelClass"
      >
        <template #label>
          {{ actualLabel }}
        </template>
        <o-button
          v-if="canShowLocateMeButton"
          class="!h-auto"
          ref="mapMarker"
          icon-right="map-marker"
          @click="locateMe"
          :title="t('Use my location')"
        />
        <o-autocomplete
          :data="addressData"
          v-model="queryTextWithDefault"
          :placeholder="placeholderWithDefault"
          :formatter="(elem: IAddress) => addressFullName(elem)"
          :debounce="debounceDelay"
          @input="asyncData"
          :icon="canShowLocateMeButton ? null : 'map-marker'"
          expanded
          @select="setSelected"
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
            <p class="text-small">
              {{ addressToPoiInfos(option).alternativeName }}
            </p>
          </template>
          <template #empty>
            <template v-if="isFetching">{{ t("Searching…") }}</template>
            <template v-else-if="queryTextWithDefault.length >= 3">
              <p>
                {{
                  t('No results for "{queryText}"', {
                    queryText: queryTextWithDefault,
                  })
                }}
              </p>
              <p>
                {{
                  t(
                    "You can try another search term or add the address details manually below."
                  )
                }}
              </p>
            </template>
          </template>
        </o-autocomplete>
        <o-button
          :disabled="!queryTextWithDefault"
          @click="resetAddress"
          class="reset-area !h-auto"
          icon-left="close"
          :title="t('Clear address field')"
        />
      </o-field>
      <p v-if="gettingLocation" class="flex gap-2">
        <Loading class="animate-spin" />
        {{ t("Getting location") }}
      </p>
      <div
        class="mt-2 p-2 rounded-lg shadow-md bg-white dark:bg-violet-3"
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
    <o-collapse
      v-model:open="detailsAddress"
      :aria-id="`${id}-address-details`"
      class="my-3"
      v-if="allowManualDetails"
    >
      <template #trigger>
        <o-button
          variant="primary"
          outlined
          :aria-controls="`${id}-address-details`"
          :icon-right="detailsAddress ? 'chevron-up' : 'chevron-down'"
        >
          {{ t("Details") }}
        </o-button>
      </template>
      <form @submit.prevent="saveManualAddress">
        <header>
          <h2>{{ t("Manually enter address") }}</h2>
        </header>
        <section>
          <o-field :label="t('Name')" labelFor="addressNameInput">
            <o-input
              aria-required="true"
              required
              v-model="selected.description"
              id="addressNameInput"
              expanded
            />
          </o-field>

          <o-field :label="t('Street')" labelFor="streetInput">
            <o-input v-model="selected.street" id="streetInput" expanded />
          </o-field>

          <o-field grouped>
            <o-field :label="t('Postal Code')" labelFor="postalCodeInput">
              <o-input
                v-model="selected.postalCode"
                id="postalCodeInput"
                expanded
              />
            </o-field>

            <o-field :label="t('Locality')" labelFor="localityInput">
              <o-input
                v-model="selected.locality"
                id="localityInput"
                expanded
              />
            </o-field>
          </o-field>

          <o-field grouped>
            <o-field :label="t('Region')" labelFor="regionInput">
              <o-input v-model="selected.region" id="regionInput" expanded />
            </o-field>

            <o-field :label="t('Country')" labelFor="countryInput">
              <o-input v-model="selected.country" id="countryInput" expanded />
            </o-field>
          </o-field>
        </section>
        <footer class="mt-3 flex gap-2 items-center">
          <o-button native-type="submit">
            {{ t("Save") }}
          </o-button>
          <o-button outlined type="button" @click="resetAddress">
            {{ t("Clear") }}
          </o-button>
          <p>
            {{
              t(
                "You can drag and drop the marker below to the desired location"
              )
            }}
          </p>
        </footer>
      </form>
    </o-collapse>
    <div
      class="map"
      v-if="!hideMap && !disabled && (selected.geom || detailsAddress)"
    >
      <map-leaflet
        :coords="selected.geom ?? defaultCoords"
        :marker="mapMarkerValue"
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
  resetAddress as resetAddressAction,
} from "../../types/address.model";
import AddressInfo from "../../components/Address/AddressInfo.vue";
import {
  computed,
  ref,
  watch,
  defineAsyncComponent,
  onMounted,
  reactive,
  onBeforeMount,
} from "vue";
import { useI18n } from "vue-i18n";
import { useGeocodingAutocomplete } from "@/composition/apollo/config";
import { ADDRESS } from "@/graphql/address";
import { useReverseGeocode } from "@/composition/apollo/address";
import { useLazyQuery } from "@vue/apollo-composable";
import { AddressSearchType } from "@/types/enums";
import Loading from "vue-material-design-icons/Loading.vue";
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
    defaultCoords?: string;
    allowManualDetails?: boolean;
  }>(),
  {
    defaultCoords: "0;0",
    labelClass: "",
    disabled: false,
    hideMap: false,
    hideSelected: false,
    allowManualDetails: false,
  }
);

const componentId = ref(0);

const emit = defineEmits(["update:modelValue"]);

const gettingLocationError = ref<string | null>(null);
const gettingLocation = ref(false);
const mapDefaultZoom = computed(() => {
  if (selected.description) {
    return 15;
  }
  return 5;
});

const addressData = ref<IAddress[]>([]);

const defaultAddress = new Address();
defaultAddress.geom = undefined;
defaultAddress.id = undefined;
const selected = reactive<IAddress>(defaultAddress);

const detailsAddress = ref(false);

const isFetching = ref(false);

const mapMarker = ref();

const placeholderWithDefault = computed(
  () => props.placeholder ?? t("e.g. 10 Rue Jangot")
);

onBeforeMount(() => {
  componentId.value += 1;
});

const id = computed((): string => {
  return `full-address-autocomplete-${componentId.value}`;
});

const modelValue = computed(() => props.modelValue);

watch(modelValue, () => {
  console.debug("modelValue changed");
  setSelected(modelValue.value);
});

onMounted(() => {
  setSelected(modelValue.value);
});

const setSelected = (newValue: IAddress | null) => {
  if (!newValue) return;
  console.debug("setting selected to model value");
  Object.assign(selected, newValue);
  emit("update:modelValue", selected);
};

const saveManualAddress = (): void => {
  console.debug("saving address");
  selected.id = undefined;
  selected.originId = undefined;
  selected.url = undefined;
  emit("update:modelValue", selected);
  detailsAddress.value = false;
};

const checkCurrentPosition = (e: LatLng): boolean => {
  console.debug("checkCurrentPosition");
  if (!selected?.geom || !e) return false;
  const lat = parseFloat(selected?.geom.split(";")[1]);
  const lon = parseFloat(selected?.geom.split(";")[0]);

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

const { load: searchAddressLoad, refetch: searchAddressRefetch } =
  useLazyQuery<{
    searchAddress: IAddress[];
  }>(ADDRESS);

const asyncData = async (query: string): Promise<void> => {
  console.debug("Finding addresses");
  if (!query.length) {
    addressData.value = [];
    Object.assign(selected, defaultAddress);
    return;
  }

  if (query.length < 3) {
    addressData.value = [];
    return;
  }

  isFetching.value = true;

  try {
    const queryVars = {
      query,
      locale: locale,
      type: props.resultType,
    };

    const result =
      (await searchAddressLoad(undefined, queryVars)) ||
      (await searchAddressRefetch(queryVars))?.data;

    if (!result) {
      isFetching.value = false;
      return;
    }
    console.debug("onAddressSearchResult", result.searchAddress);
    addressData.value = result.searchAddress;
    isFetching.value = false;
  } catch (e) {
    console.error(e);
    return;
  }
};

const selectedAddressText = computed(() => {
  if (!selected) return undefined;
  return addressFullName(selected);
});

const queryText = ref();

const queryTextWithDefault = computed({
  get() {
    return (
      queryText.value ?? selectedAddressText.value ?? props.defaultText ?? ""
    );
  },
  set(newValue: string) {
    queryText.value = newValue;
  },
});

const resetAddress = (): void => {
  console.debug("resetting address");
  emit("update:modelValue", null);
  resetAddressAction(selected);
  queryTextWithDefault.value = "";
};

const locateMe = async (): Promise<void> => {
  gettingLocation.value = true;
  gettingLocationError.value = null;
  try {
    const location = await getLocation();
    // mapDefaultZoom.value = 12;
    reverseGeoCode(
      new LatLng(location.coords.latitude, location.coords.longitude),
      12
    );
  } catch (e: any) {
    gettingLocationError.value = e.message;
  }
  gettingLocation.value = false;
};

const { load: loadReverseGeocode } = useReverseGeocode();

const reverseGeoCode = async (e: LatLng, zoom: number) => {
  console.debug("reverse geocode");

  // If the details is opened, just update coords, don't reverse geocode
  if (e && detailsAddress.value) {
    selected.geom = `${e.lng};${e.lat}`;
    console.debug("no reverse geocode, just setting new coords");
    return;
  }

  // If the position has been updated through autocomplete selection, no need to geocode it!
  if (!e || checkCurrentPosition(e)) return;

  try {
    const result = await loadReverseGeocode(undefined, {
      latitude: e.lat,
      longitude: e.lng,
      zoom,
      locale: locale as unknown as string,
    });
    if (!result) return;
    addressData.value = result.reverseGeocode;

    if (addressData.value.length > 0) {
      const foundAddress = addressData.value[0];
      Object.assign(selected, foundAddress);
      console.debug("reverse geocode succeded, setting new address");
      queryTextWithDefault.value = addressFullName(foundAddress);
      emit("update:modelValue", selected);
    }
  } catch (err) {
    console.error("Failed to load reverse geocode", err);
  }
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

const mapMarkerValue = computed(() => {
  if (!selected.description) return undefined;
  return {
    text: [
      addressToPoiInfos(selected).name,
      addressToPoiInfos(selected).alternativeName,
    ],
    icon: addressToPoiInfos(selected).poiIcon.icon,
  };
});

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
