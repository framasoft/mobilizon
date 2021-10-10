<template>
  <div class="modal-card">
    <header class="modal-card-head">
      <button type="button" class="delete" @click="$emit('close')" />
    </header>
    <div class="modal-card-body">
      <section class="map">
        <map-leaflet
          :coords="physicalAddress.geom"
          :marker="{
            text: physicalAddress.fullName,
            icon: physicalAddress.poiInfos.poiIcon.icon,
          }"
        />
      </section>
      <section class="columns is-centered map-footer">
        <div class="column is-half has-text-centered">
          <p class="address">
            <i class="mdi mdi-map-marker"></i>
            {{ physicalAddress.fullName }}
          </p>
          <p class="getting-there">{{ $t("Getting there") }}</p>
          <div
            class="buttons"
            v-if="
              addressLinkToRouteByCar ||
              addressLinkToRouteByBike ||
              addressLinkToRouteByFeet
            "
          >
            <a
              class="button"
              target="_blank"
              v-if="addressLinkToRouteByFeet"
              :href="addressLinkToRouteByFeet"
            >
              <i class="mdi mdi-walk"></i
            ></a>
            <a
              class="button"
              target="_blank"
              v-if="addressLinkToRouteByBike"
              :href="addressLinkToRouteByBike"
            >
              <i class="mdi mdi-bike"></i
            ></a>
            <a
              class="button"
              target="_blank"
              v-if="addressLinkToRouteByTransit"
              :href="addressLinkToRouteByTransit"
            >
              <i class="mdi mdi-bus"></i
            ></a>
            <a
              class="button"
              target="_blank"
              v-if="addressLinkToRouteByCar"
              :href="addressLinkToRouteByCar"
            >
              <i class="mdi mdi-car"></i>
            </a>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>
<script lang="ts">
import { Address, IAddress } from "@/types/address.model";
import { RoutingTransportationType, RoutingType } from "@/types/enums";
import { PropType } from "vue";
import { Component, Vue, Prop } from "vue-property-decorator";

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

@Component({
  components: {
    "map-leaflet": () =>
      import(/* webpackChunkName: "map" */ "../../components/Map.vue"),
  },
})
export default class EventMap extends Vue {
  @Prop({ type: Object as PropType<IAddress> }) address!: IAddress;
  @Prop({ type: String }) routingType!: RoutingType;

  get physicalAddress(): Address | null {
    if (!this.address) return null;

    return new Address(this.address);
  }

  makeNavigationPath(
    transportationType: RoutingTransportationType
  ): string | undefined {
    const geometry = this.physicalAddress?.geom;
    if (geometry) {
      /**
       * build urls to routing map
       */
      if (!RoutingParamType[this.routingType][transportationType]) {
        return;
      }

      const urlGeometry = geometry.split(";").reverse().join(",");

      switch (this.routingType) {
        case RoutingType.GOOGLE_MAPS:
          return `https://maps.google.com/?saddr=Current+Location&daddr=${urlGeometry}&${
            RoutingParamType[this.routingType][transportationType]
          }`;
        case RoutingType.OPENSTREETMAP:
        default: {
          const bboxX = geometry.split(";").reverse()[0];
          const bboxY = geometry.split(";").reverse()[1];
          return `https://www.openstreetmap.org/directions?from=&to=${urlGeometry}&${
            RoutingParamType[this.routingType][transportationType]
          }#map=14/${bboxX}/${bboxY}`;
        }
      }
    }
  }

  get addressLinkToRouteByCar(): undefined | string {
    return this.makeNavigationPath(RoutingTransportationType.CAR);
  }

  get addressLinkToRouteByBike(): undefined | string {
    return this.makeNavigationPath(RoutingTransportationType.BIKE);
  }

  get addressLinkToRouteByFeet(): undefined | string {
    return this.makeNavigationPath(RoutingTransportationType.FOOT);
  }

  get addressLinkToRouteByTransit(): undefined | string {
    return this.makeNavigationPath(RoutingTransportationType.TRANSIT);
  }
}
</script>
<style lang="scss" scoped>
.modal-card-head {
  justify-content: flex-end;
  button.delete {
    margin-right: 1rem;
  }
}

section.map {
  height: calc(100% - 8rem);
  width: calc(100% - 20px);
}

section.map-footer {
  p.address {
    margin: 1rem auto;
  }
  div.buttons {
    justify-content: center;
  }
}
</style>
