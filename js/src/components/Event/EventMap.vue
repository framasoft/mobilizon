<template>
  <div class="">
    <div class="text-end">
      <button @click="emit('close')">
        <Close />
        <span class="sr-only">{{ t("Close map") }}</span>
      </button>
    </div>
    <section class="map">
      <map-leaflet
        v-if="physicalAddress?.geom"
        :coords="physicalAddress.geom"
        :marker="{
          text: physicalAddress.fullName,
          icon: physicalAddress.poiInfos.poiIcon.icon,
        }"
      />
    </section>
    <section class="flex flex-col items-center mt-4">
      <p v-if="physicalAddress?.fullName" class="flex gap-2 text-xl font-bold">
        <MapMarker />
        {{ physicalAddress.fullName }}
      </p>
      <p class="mt-4">{{ t("Getting there") }}</p>
      <div
        class="flex gap-2"
        v-if="
          addressLinkToRouteByCar ||
          addressLinkToRouteByBike ||
          addressLinkToRouteByFeet
        "
      >
        <o-button
          tag="a"
          target="_blank"
          v-if="addressLinkToRouteByFeet"
          :href="addressLinkToRouteByFeet"
        >
          <Walk />
          <span class="sr-only">{{ t("On foot") }}</span>
        </o-button>
        <o-button
          tag="a"
          target="_blank"
          v-if="addressLinkToRouteByBike"
          :href="addressLinkToRouteByBike"
        >
          <Bike />
          <span class="sr-only">{{ t("By bike") }}</span>
        </o-button>
        <o-button
          tag="a"
          target="_blank"
          v-if="addressLinkToRouteByTransit"
          :href="addressLinkToRouteByTransit"
        >
          <Bus />
          <span class="sr-only">{{ t("By transit") }}</span>
        </o-button>
        <o-button
          tag="a"
          target="_blank"
          v-if="addressLinkToRouteByCar"
          :href="addressLinkToRouteByCar"
        >
          <Car />
          <span class="sr-only">{{ t("By car") }}</span>
        </o-button>
      </div>
    </section>
  </div>
</template>
<script lang="ts" setup>
import { Address, IAddress } from "@/types/address.model";
import { RoutingTransportationType, RoutingType } from "@/types/enums";
import { computed, defineAsyncComponent } from "vue";
import { useI18n } from "vue-i18n";
import Car from "vue-material-design-icons/Car.vue";
import Bike from "vue-material-design-icons/Bike.vue";
import Bus from "vue-material-design-icons/Bus.vue";
import Walk from "vue-material-design-icons/Walk.vue";
import MapMarker from "vue-material-design-icons/MapMarker.vue";
import Close from "vue-material-design-icons/Close.vue";

const { t } = useI18n({ useScope: "global" });

const RoutingParamType = {
  [RoutingType.OPENSTREETMAP]: {
    [RoutingTransportationType.FOOT]: "engine=fossgis_osrm_foot",
    [RoutingTransportationType.BIKE]: "engine=fossgis_osrm_bike",
    [RoutingTransportationType.TRANSIT]: null,
    [RoutingTransportationType.CAR]: "engine=fossgis_osrm_car",
  },
  [RoutingType.GOOGLE_MAPS]: {
    [RoutingTransportationType.FOOT]: "dirflg=w",
    [RoutingTransportationType.BIKE]: "dirflg=b",
    [RoutingTransportationType.TRANSIT]: "dirflg=r",
    [RoutingTransportationType.CAR]: "driving",
  },
};

const MapLeaflet = defineAsyncComponent(
  () => import("@/components/LeafletMap.vue")
);

const props = defineProps<{
  address: IAddress;
  routingType: RoutingType;
}>();

const emit = defineEmits(["close"]);

const physicalAddress = computed((): Address | null => {
  if (!props.address) return null;

  return new Address(props.address);
});

const makeNavigationPath = (
  transportationType: RoutingTransportationType
): string | undefined => {
  const geometry = physicalAddress.value?.geom;
  if (geometry) {
    /**
     * build urls to routing map
     */
    if (!RoutingParamType[props.routingType][transportationType]) {
      return;
    }

    const urlGeometry = geometry.split(";").reverse().join(",");

    switch (props.routingType) {
      case RoutingType.GOOGLE_MAPS:
        return `https://maps.google.com/?saddr=Current+Location&daddr=${urlGeometry}&${
          RoutingParamType[props.routingType][transportationType]
        }`;
      case RoutingType.OPENSTREETMAP:
      default: {
        const bboxX = geometry.split(";").reverse()[0];
        const bboxY = geometry.split(";").reverse()[1];
        return `https://www.openstreetmap.org/directions?from=&to=${urlGeometry}&${
          RoutingParamType[props.routingType][transportationType]
        }#map=14/${bboxX}/${bboxY}`;
      }
    }
  }
};

const addressLinkToRouteByCar = computed((): undefined | string => {
  return makeNavigationPath(RoutingTransportationType.CAR);
});

const addressLinkToRouteByBike = computed((): undefined | string => {
  return makeNavigationPath(RoutingTransportationType.BIKE);
});

const addressLinkToRouteByFeet = computed((): undefined | string => {
  return makeNavigationPath(RoutingTransportationType.FOOT);
});

const addressLinkToRouteByTransit = computed((): undefined | string => {
  return makeNavigationPath(RoutingTransportationType.TRANSIT);
});
</script>
<style lang="scss" scoped>
section.map {
  height: 75vh;
  width: 100%;
}
</style>
