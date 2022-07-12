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
    >
      <l-tile-layer :url="tiles?.endpoint" :attribution="attribution">
      </l-tile-layer>
      <l-control-zoom
        position="topleft"
        :zoomInTitle="$t('Zoom in')"
        :zoomOutTitle="$t('Zoom out')"
      ></l-control-zoom>
      <!-- <v-locatecontrol
        v-if="canDoGeoLocation"
        :options="{ icon: 'mdi mdi-map-marker' }"
      /> -->
      <l-marker
        :lat-lng="[lat, lon]"
        @add="openPopup"
        @update:latLng="updateDraggableMarkerPosition"
        :draggable="!readOnly"
      >
        <l-popup v-if="popupMultiLine">
          <span v-for="line in popupMultiLine" :key="line"
            >{{ line }}<br
          /></span>
        </l-popup>
      </l-marker>
    </l-map>
  </div>
</template>

<script lang="ts" setup>
import { Icon, LatLng, LeafletMouseEvent, LeafletEvent } from "leaflet";
import "leaflet/dist/leaflet.css";
import {
  LMap,
  LTileLayer,
  LMarker,
  LPopup,
  LIcon,
  LControlZoom,
} from "@vue-leaflet/vue-leaflet";
// import Vue2LeafletLocateControl from "@/components/Map/Vue2LeafletLocateControl.vue";
import { computed, nextTick, onMounted, ref } from "vue";
import { useMapTiles } from "@/composition/apollo/config";
import { useI18n } from "vue-i18n";

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

onMounted(() => {
  // this part resolve an issue where the markers would not appear
  // delete Icon.Default.prototype._getIconUrl;
  // Icon.Default.mergeOptions({
  //   iconRetinaUrl: require("leaflet/dist/images/marker-icon-2x.png"),
  //   iconUrl: require("leaflet/dist/images/marker-icon.png"),
  //   shadowUrl: require("leaflet/dist/images/marker-shadow.png"),
  // });
});

const openPopup = async (event: LeafletEvent): Promise<void> => {
  await nextTick();
  event.target.openPopup();
};

const mergedOptions = computed((): Record<string, unknown> => {
  return { ...defaultOptions, ...props.options };
});

const lat = computed((): number => {
  return Number.parseFloat(props.coords?.split(";")[1]);
});

const lon = computed((): number => {
  return Number.parseFloat(props.coords.split(";")[0]);
});

const popupMultiLine = computed((): Array<string | undefined> => {
  if (Array.isArray(props.marker?.text)) {
    return props.marker?.text as string[];
  }
  return [props.marker?.text];
});

const clickMap = (event: LeafletMouseEvent): void => {
  updateDraggableMarkerPosition(event.latlng);
};

const updateDraggableMarkerPosition = (e: LatLng): void => {
  if (props.updateDraggableMarkerCallback) {
    props.updateDraggableMarkerCallback(e, zoom.value);
  }
};

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
