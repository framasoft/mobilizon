<template>
  <div class="map-container">
    <l-map
      :zoom="mergedOptions.zoom"
      :style="`height: ${mergedOptions.height}; width: ${mergedOptions.width}`"
      class="leaflet-map"
      :center="[lat, lon]"
      @click="clickMap"
      @update:zoom="updateZoom"
      :options="{ zoomControl: false }"
      ref="mapComponent"
      @ready="onMapReady"
    >
      <l-tile-layer :url="tiles?.endpoint" :attribution="attribution">
      </l-tile-layer>
      <l-control-zoom
        position="topleft"
        :zoomInTitle="$t('Zoom in')"
        :zoomOutTitle="$t('Zoom out')"
      ></l-control-zoom>
      <l-marker
        :lat-lng="[lat, lon]"
        @add="openPopup"
        @update:latLng="updateDraggableMarkerPositionDebounced"
        :draggable="!readOnly"
      >
        <l-icon
          :icon-size="[48, 48]"
          :shadow-size="[30, 30]"
          :icon-anchor="[24, 48]"
          :popup-anchor="[-24, -40]"
        >
          <MapMarker :size="48" class="text-mbz-purple" />
        </l-icon>
        <l-popup v-if="popupMultiLine" :options="{ offset: new Point(22, 8) }">
          <span v-for="line in popupMultiLine" :key="line"
            >{{ line }}<br
          /></span>
        </l-popup>
      </l-marker>
    </l-map>
    <CrosshairsGps ref="locationIcon" class="hidden" />
  </div>
</template>

<script lang="ts" setup>
import {
  LatLng,
  LeafletMouseEvent,
  LeafletEvent,
  Control,
  DomUtil,
  Map,
  Point,
} from "leaflet";
import "leaflet/dist/leaflet.css";
import {
  LMap,
  LTileLayer,
  LMarker,
  LPopup,
  LIcon,
  LControlZoom,
} from "@vue-leaflet/vue-leaflet";
import { computed, nextTick, onMounted, ref } from "vue";
import { useMapTiles } from "@/composition/apollo/config";
import { useI18n } from "vue-i18n";
import Locatecontrol from "leaflet.locatecontrol";
import CrosshairsGps from "vue-material-design-icons/CrosshairsGps.vue";
import MapMarker from "vue-material-design-icons/MapMarker.vue";
import { useDebounceFn } from "@vueuse/core";

const props = withDefaults(
  defineProps<{
    readOnly?: boolean;
    coords: string;
    marker?: { text: string | string[]; icon: string };
    options?: Record<string, unknown>;
    updateDraggableMarkerCallback?: (latlng: LatLng, zoom: number) => void;
  }>(),
  {
    readOnly: true,
  }
);

const defaultOptions: {
  zoom: number;
  height: string;
  width: string;
} = {
  zoom: 15,
  height: "100%",
  width: "100%",
};

const zoom = ref(defaultOptions.zoom);

const mapComponent = ref();
const mapObject = ref<Map>();
const locateControl = ref<Control.Locate>();
const locationIcon = ref();

const locationIconHTML = computed(() => locationIcon.value?.$el.innerHTML);

onMounted(async () => {
  // this part resolve an issue where the markers would not appear
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  // eslint-disable-next-line no-underscore-dangle
  // delete Icon.Default.prototype._getIconUrl;
  // Icon.Default.mergeOptions({
  //   iconRetinaUrl: require("leaflet/dist/images/marker-icon-2x.png"),
  //   iconUrl: require("leaflet/dist/images/marker-icon.png"),
  //   shadowUrl: require("leaflet/dist/images/marker-shadow.png"),
  // });
});

const onMapReady = async () => {
  mapObject.value = mapComponent.value.leafletObject;
  mountLocateControl();
};

const mountLocateControl = () => {
  if (canDoGeoLocation.value && mapObject.value) {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    locateControl.value = new Locatecontrol({
      strings: { title: t("Show me where I am") as string },
      position: "topleft",
      drawCircle: false,
      drawMarker: false,
      createButtonCallback(container: HTMLElement | undefined, options: any) {
        const link = DomUtil.create(
          "a",
          "leaflet-bar-part leaflet-bar-part-single",
          container
        );
        link.title = options.strings.title;
        link.href = "#";
        link.setAttribute("role", "button");

        const icon = DomUtil.create(
          "span",
          "material-design-icon rss-icon",
          link
        );
        icon.setAttribute("aria-hidden", "true");
        icon.setAttribute("role", "img");
        icon.insertAdjacentHTML("beforeend", locationIconHTML.value);
        return { link, icon };
      },
      ...props.options,
    }) as Control.Locate;
    locateControl.value?.addTo(mapObject.value);
  }
};

const openPopup = async (event: LeafletEvent): Promise<void> => {
  await nextTick();
  event.target.openPopup();
};

const mergedOptions = computed((): Record<string, unknown> => {
  return { ...defaultOptions, ...props.options };
});

const lat = computed((): number => {
  return Number.parseFloat(props.coords?.split(";")[1] || "0");
});

const lon = computed((): number => {
  return Number.parseFloat(props.coords?.split(";")[0] || "0");
});

const popupMultiLine = computed((): Array<string> | undefined => {
  if (Array.isArray(props.marker?.text)) {
    return props.marker?.text as string[];
  }
  if (props.marker?.text) {
    return [props.marker?.text];
  }
  return undefined;
});

const clickMap = (event: LeafletMouseEvent): void => {
  updateDraggableMarkerPositionDebounced(event.latlng);
};

const updateDraggableMarkerPosition = (e: LatLng): void => {
  if (props.updateDraggableMarkerCallback) {
    props.updateDraggableMarkerCallback(e, zoom.value);
  }
};

const updateDraggableMarkerPositionDebounced = useDebounceFn((e: LatLng) => {
  updateDraggableMarkerPosition(e);
}, 1000);

const updateZoom = (newZoom: number): void => {
  zoom.value = newZoom;
};

const { tiles } = useMapTiles();

const { t } = useI18n({ useScope: "global" });

const attribution = computed((): string => {
  return tiles.value?.attribution ?? t("© The OpenStreetMap Contributors");
});

const canDoGeoLocation = computed((): boolean => {
  return window.isSecureContext;
});
</script>
<style lang="scss" scoped>
div.map-container {
  height: 100%;
  width: 100%;

  .leaflet-map {
    z-index: 20;
  }
}
</style>
<style>
@import "leaflet.locatecontrol/dist/L.Control.Locate.css";

.leaflet-div-icon {
  background: unset !important;
  border: unset !important;
}
</style>
