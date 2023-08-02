<template>
  <div class="relative my-2">
    <div style="height: 70vh" id="mapMountPoint" />
    <vue-bottom-sheet
      v-if="activeElement"
      ref="myBottomSheet"
      class="md:hidden"
      max-height="70%"
      :background-scrollable="false"
    >
      <event-card
        v-if="instanceOfIEvent(activeElement)"
        :event="activeElement as IEvent"
        mode="column"
        :options="{
          isRemoteEvent: activeElement.__typename === 'EventResult',
          isLoggedIn,
        }"
      />
      <group-card
        v-else
        :group="activeElement as IGroup"
        mode="column"
        :isRemoteGroup="activeElement.__typename === 'GroupResult'"
        :isLoggedIn="isLoggedIn"
      />
    </vue-bottom-sheet>
    <div
      class="absolute hidden md:block bottom-0 md:top-8 right-0 h-48 w-full md:w-80 overflow-y-visible text-white [box-shadow:0 6px 9px 2px rgba(119,119,119,.75)] -my-4 px-2 z-[1100]"
      v-if="activeElement"
    >
      <event-card
        v-if="instanceOfIEvent(activeElement)"
        :event="activeElement as IEvent"
        mode="column"
        :options="{
          isRemoteEvent: activeElement.__typename === 'EventResult',
          isLoggedIn,
        }"
      />
      <group-card
        v-else
        :group="activeElement as IGroup"
        mode="column"
        :isRemoteGroup="activeElement.__typename === 'GroupResult'"
        :isLoggedIn="isLoggedIn"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import "leaflet/dist/leaflet.css";
import {
  computed,
  createApp,
  DefineComponent,
  h,
  onBeforeUnmount,
  onMounted,
  ref,
  watch,
} from "vue";
import VueBottomSheet from "@/components/Map/VueBottomSheet.vue";
import {
  map,
  LatLngBounds,
  tileLayer,
  marker,
  divIcon,
  Map,
  Marker,
} from "leaflet";
import { MarkerClusterGroup } from "leaflet.markercluster/src";
import { IGroup } from "@/types/actor";
import { IEvent, instanceOfIEvent } from "@/types/event.model";
import { ContentType } from "@/types/enums";
import Calendar from "vue-material-design-icons/Calendar.vue";
import AccountMultiple from "vue-material-design-icons/AccountMultiple.vue";
import GroupCard from "@/components/Group/GroupCard.vue";
import EventCard from "@/components/Event/EventCard.vue";
import debounce from "lodash/debounce";
import { Paginate } from "@/types/paginate";
import { TypeNamed } from "@/types/apollo";

const mapElement = ref<Map>();
const markers = ref<MarkerClusterGroup>();
const myBottomSheet = ref<typeof VueBottomSheet>();

const props = defineProps<{
  contentType: ContentType;
  events: Paginate<TypeNamed<IEvent>>;
  groups: Paginate<TypeNamed<IGroup>>;
  latitude?: number;
  longitude?: number;
  isLoggedIn: boolean | undefined;
}>();

const emit = defineEmits<{
  (
    e: "map-updated",
    { bounds, zoom }: { bounds: LatLngBounds; zoom: number }
  ): void;
}>();

const activeElement = ref<TypeNamed<IEvent> | TypeNamed<IGroup> | null>(null);

const events = computed(() => props.events?.elements ?? []);
const groups = computed(() => props.groups?.elements ?? []);

watch([events, groups], update);

function update() {
  if (!mapElement.value || !mapElement.value.getBounds) return;
  const rawBounds: LatLngBounds = mapElement.value.getBounds();
  const bounds: LatLngBounds = mapElement.value.wrapLatLngBounds(rawBounds);
  if (
    bounds.getNorthWest().lat === 0 ||
    bounds.getNorthWest().lat === bounds.getSouthEast().lat
  )
    return;
  const zoom = mapElement.value.getZoom();
  emit("map-updated", { bounds, zoom });
}

onBeforeUnmount(() => {
  if (mapElement.value) {
    mapElement.value.remove();
  }
});

const initialView = computed<[[number, number], number]>(() => {
  if (props.latitude && props.longitude) {
    return [[props.latitude, props.longitude], 12];
  }
  return [[0, 0], 3];
});

watch(initialView, ([latlng, zoom]) => {
  setLatLng(latlng, zoom);
});

const setLatLng = (latlng: [number, number], zoom: number) => {
  console.debug("setting view to ", latlng, zoom);
  mapElement.value?.setView(latlng, zoom);
};

onMounted(async () => {
  mapElement.value = map("mapMountPoint");
  setLatLng(...initialView.value);
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  // eslint-disable-next-line no-underscore-dangle
  mapElement.value._onResize();
  mapElement.value.on("click", () => {
    activeElement.value = null;
    if (myBottomSheet.value) {
      myBottomSheet.value.close();
    }
  });
  markers.value = new MarkerClusterGroup({ chunkedLoading: true });

  mapElement.value.on("zoom", debounce(update, 1000));
  mapElement.value.on("moveend", debounce(update, 1000));

  tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution:
      '&copy; <a href="https://osm.org/copyright">OpenStreetMap</a> contributors',
    className: "map-tiles",
  }).addTo(mapElement.value);
});

const categoryToColorClass = (element: IEvent | IGroup): string => {
  if (instanceOfIEvent(element)) {
    return "marker-event";
  }
  return "marker-group";
};

const pointToLayer = (
  element: TypeNamed<IEvent> | TypeNamed<IGroup>,
  latlng: { lat: number; lng: number }
): Marker => {
  const icon = divIcon({
    html: `<div class="marker-container ${categoryToColorClass(element)}">
            <div class="pin-icon-container">
              <svg width="24" height="24" stroke-width="1.5" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M20 10C20 14.4183 12 22 12 22C12 22 4 14.4183 4 10C4 5.58172 7.58172 2 12 2C16.4183 2 20 5.58172 20 10Z" stroke="currentColor" stroke-width="1.5"></path>
              </svg>
            </div>
            <div class="element-icon-container text-black">
              ${instanceOfIEvent(element) ? calendarHTML : AccountMultipleHTML}
            </div>
          </div>`,
    iconSize: [50, 50],
    iconAnchor: [25, 50],
    // iconSize: [
    //   MARKER_TOUCH_TARGET_SIZE * 0.5,
    //   MARKER_TOUCH_TARGET_SIZE * 0.5,
    // ],
  });

  return marker(latlng, { icon }).on("click", () => {
    activeElement.value = element;
    if (myBottomSheet.value) {
      myBottomSheet.value.open();
    }
  });
};

// https://stackoverflow.com/a/68319134/10204399
const vueComponentToHTML = (
  component: DefineComponent,
  localProps: Record<string, any> = {}
) => {
  const tempApp = createApp({
    render() {
      return h(component, localProps);
    },
  });

  // in Vue 3 we need real element to mount to unlike in Vue 2 where mount() could be called without argument...
  const el = document.createElement("div");
  const mountedApp = tempApp.mount(el);

  const html = mountedApp.$el.outerHTML as string;
  // tempApp.unmount();
  return html;
};

const calendarHTML = vueComponentToHTML(Calendar);
const AccountMultipleHTML = vueComponentToHTML(AccountMultiple);

update();

const eventMarkers = computed(() => {
  return events.value?.reduce((acc, event) => {
    if (event.physicalAddress?.geom) {
      const [lng, lat] = event.physicalAddress.geom.split(";");
      return [
        ...acc,
        pointToLayer(event, {
          lng: Number.parseFloat(lng),
          lat: Number.parseFloat(lat),
        }),
      ];
    }
    return acc;
  }, [] as Marker[]);
});

const groupMarkers = computed(() => {
  return groups.value?.reduce((acc: Marker[], group: TypeNamed<IGroup>) => {
    if (group.physicalAddress?.geom) {
      const [lng, lat] = group.physicalAddress.geom.split(";");
      return [
        ...acc,
        pointToLayer(group, {
          lng: Number.parseFloat(lng),
          lat: Number.parseFloat(lat),
        }),
      ];
    }
    return acc;
  }, [] as Marker[]);
});

watch([markers, eventMarkers, groupMarkers], () => {
  if (!markers.value) return;
  console.debug(
    "something changed in the search map",
    markers.value,
    eventMarkers.value,
    groupMarkers.value
  );
  markers.value?.clearLayers();
  if (props.contentType !== ContentType.GROUPS) {
    eventMarkers.value?.forEach((markerToAdd) => {
      console.debug("adding event marker layer to markers");
      markers.value.addLayer(markerToAdd);
    });
  }
  if (props.contentType !== ContentType.EVENTS) {
    groupMarkers.value?.forEach((markerToAdd) => {
      console.debug("adding group marker layer to markers");
      markers.value.addLayer(markerToAdd);
    });
  }
  mapElement.value?.addLayer(markers.value);
});
</script>
<style>
/*
* https://github.com/mapbox/supercluster/blob/f073fade1caae0b2b1beffd013b74ff024ff413b/demo/cluster.css
*/
.marker-cluster-small {
  background-color: rgba(181, 226, 140, 0.6);
}

.marker-cluster-small div {
  background-color: rgba(110, 204, 57, 0.6);
}

.marker-cluster-medium {
  background-color: rgba(241, 211, 87, 0.6);
}

.marker-cluster-medium div {
  background-color: rgba(240, 194, 12, 0.6);
}

.marker-cluster-large {
  background-color: rgba(253, 156, 115, 0.6);
}

.marker-cluster-large div {
  background-color: rgba(241, 128, 23, 0.6);
}

.marker-cluster {
  background-clip: padding-box;
  border-radius: 20px;
}

.marker-cluster div {
  width: 30px;
  height: 30px;
  margin-left: 5px;
  margin-top: 5px;

  text-align: center;
  border-radius: 15px;
  font:
    12px "Helvetica Neue",
    Arial,
    Helvetica,
    sans-serif;
}

.marker-cluster span {
  line-height: 30px;
}

:root {
  --map-tiles-filter: brightness(0.6) invert(1) contrast(3) hue-rotate(200deg)
    saturate(0.3) brightness(0.7);
}

@media (prefers-color-scheme: dark) {
  .map-tiles {
    filter: var(--map-tiles-filter, none);
  }
}

.leaflet-div-icon {
  background: none !important;
  border: none !important;
}

.marker-container {
  position: relative;
}

.marker-container.marker-event .pin-icon-container svg {
  fill: yellow;
  color: black;
}

.marker-container.marker-group .pin-icon-container svg {
  fill: lightblue;
  color: white;
}

.pin-icon-container {
  position: absolute;
  width: 50px;
  height: 50px;
}

.pin-icon-container svg path {
  stroke-width: 1;
}

.pin-icon-container svg {
  width: 100%;
  height: 100%;
}

.element-icon-container {
  position: absolute;
  transform: translate(12px, 8px);
}
</style>
