<template>
  <div class="map-container">
    <div
      ref="mapContainer"
      :style="{ height: mergedOptions.height, width: mergedOptions.width }"
      class="maplibre-map"
    ></div>
    <CrosshairsGps ref="locationIcon" class="hidden" />
  </div>
</template>

<script lang="ts" setup>
import { computed, nextTick, ref, onMounted } from "vue";
import { useMapTiles } from "@/composition/apollo/config";
import { useI18n } from "vue-i18n";
import CrosshairsGps from "vue-material-design-icons/CrosshairsGps.vue";
import { useDebounceFn } from "@vueuse/core";
import maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';

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

const mapContainer = ref<HTMLElement | null>(null);
const mapObject = ref<maplibregl.Map | null>(null);
const locationIcon = ref();

const locationIconHTML = computed(() => locationIcon.value?.$el.innerHTML);

const onMapReady = async () => {
  if (mapObject.value) {
    mountLocateControl();
  }
};

const mountLocateControl = () => {
  if (canDoGeoLocation.value && mapObject.value) {
    const locateControl = new maplibregl.GeolocateControl({
      positionOptions: {
        enableHighAccuracy: true,
      },
      trackUserLocation: true,
      showAccuracyCircle: true,
      showUserLocation: true,
    });

    mapObject.value.addControl(locateControl, 'top-left');

    const icon = document.createElement('div');
    icon.innerHTML = locationIconHTML.value || '';
    icon.className = 'material-design-icon rss-icon';

    locateControl._geolocateButton.appendChild(icon);
  }
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

const clickMap = (event: maplibregl.MapMouseEvent): void => {
  updateDraggableMarkerPositionDebounced([event.lngLat.lat, event.lngLat.lng]);
};

const updateDraggableMarkerPosition = (coords: [number, number]): void => {
  if (props.updateDraggableMarkerCallback) {
    props.updateDraggableMarkerCallback(coords, zoom.value);
  }
};

const updateDraggableMarkerPositionDebounced = useDebounceFn((coords: [number, number]) => {
  updateDraggableMarkerPosition(coords);
}, 1000);

const updateZoom = (newZoom: number): void => {
  zoom.value = newZoom;
};

const { tiles } = useMapTiles();

const { t } = useI18n({ useScope: "global" });

const canDoGeoLocation = computed((): boolean => {
  return window.isSecureContext;
});

// URLs für die Kartenstile
const styleUrlLight = "https://api.maptiler.com/maps/streets-v2/style.json?key=HXt3vGyjL1Z3Eo8HjFVa";
const styleUrlDark = "https://api.maptiler.com/maps/streets-v2-dark/style.json?key=HXt3vGyjL1Z3Eo8HjFVa"; // Beispiel für eine Dark Mode Karte

onMounted(() => {
  // Prüfen, ob der Dark Mode aktiv ist
  const isDarkMode = document.documentElement.classList.contains('dark');
  const styleUrl = isDarkMode ? styleUrlDark : styleUrlLight;

  if (mapContainer.value) {
    mapObject.value = new maplibregl.Map({
      container: mapContainer.value,
      style: styleUrl,
      center: [lon.value, lat.value],
      zoom: mergedOptions.value.zoom as number,
    });

    mapObject.value.on('load', onMapReady);

    // Add NavigationControl (zoom buttons)
    mapObject.value.addControl(new maplibregl.NavigationControl(), 'top-right');

    if (lat.value && lon.value) {
      const marker = new maplibregl.Marker({
        draggable: !props.readOnly,
      })
        .setLngLat([lon.value, lat.value])
        .addTo(mapObject.value);

      marker.on('dragend', () => {
        const lngLat = marker.getLngLat();
        updateDraggableMarkerPositionDebounced([lngLat.lat, lngLat.lng]);
      });

      if (popupMultiLine.value) {
        // Hier wird das Popup automatisch geöffnet, wenn es Daten gibt
        const popup = new maplibregl.Popup({ offset: 25 }).setHTML(
          popupMultiLine.value.map(line => `<span>${line}</span><br />`).join('')
        );
        marker.setPopup(popup).togglePopup(); // Popup automatisch öffnen
      }
    }

    mapObject.value.on('click', clickMap);
    mapObject.value.on('zoom', () => {
      updateZoom(mapObject.value?.getZoom() || 0);
    });
  }
});
</script>

<style lang="scss" scoped>
div.map-container {
  height: 100%;
  width: 100%;

  .maplibre-map {
    z-index: 20;
  }
}

.material-design-icon.rss-icon {
  display: inline-block;
  width: 24px;
  height: 24px;
}
</style>
<style>
@import 'maplibre-gl/dist/maplibre-gl.css';

.maplibre-div-icon {
  background: unset !important;
  border: unset !important;
}
.maplibregl-popup-content {
  color: black;
}
</style>
