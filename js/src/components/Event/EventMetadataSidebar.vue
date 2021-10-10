<template>
  <div>
    <event-metadata-block
      :title="$t('Location')"
      :icon="physicalAddress ? physicalAddress.poiInfos.poiIcon.icon : 'earth'"
    >
      <div class="address-wrapper">
        <span v-if="!physicalAddress">{{ $t("No address defined") }}</span>
        <div class="address" v-if="physicalAddress">
          <address-info :address="physicalAddress" />
          <b-button
            type="is-text"
            class="map-show-button"
            @click="showMap = !showMap"
            v-if="physicalAddress.geom"
          >
            {{ $t("Show map") }}
          </b-button>
        </div>
      </div>
    </event-metadata-block>
    <event-metadata-block :title="$t('Date and time')" icon="calendar">
      <event-full-date
        :beginsOn="event.beginsOn"
        :show-start-time="event.options.showStartTime"
        :show-end-time="event.options.showEndTime"
        :endsOn="event.endsOn"
      />
    </event-metadata-block>
    <event-metadata-block
      class="metadata-organized-by"
      :title="$t('Organized by')"
    >
      <popover-actor-card
        :actor="event.organizerActor"
        v-if="!event.attributedTo"
      >
        <actor-card :actor="event.organizerActor" />
      </popover-actor-card>
      <router-link
        v-if="event.attributedTo"
        :to="{
          name: RouteName.GROUP,
          params: {
            preferredUsername: usernameWithDomain(event.attributedTo),
          },
        }"
      >
        <popover-actor-card
          :actor="event.attributedTo"
          v-if="
            !event.attributedTo || !event.options.hideOrganizerWhenGroupEvent
          "
        >
          <actor-card :actor="event.attributedTo" />
        </popover-actor-card>
      </router-link>

      <popover-actor-card
        :actor="contact"
        v-for="contact in event.contacts"
        :key="contact.id"
      >
        <actor-card :actor="contact" />
      </popover-actor-card>
    </event-metadata-block>
    <event-metadata-block
      v-if="event.onlineAddress && urlToHostname(event.onlineAddress)"
      icon="link"
      :title="$t('Website')"
    >
      <a
        target="_blank"
        rel="noopener noreferrer ugc"
        :href="event.onlineAddress"
        :title="
          $t('View page on {hostname} (in a new window)', {
            hostname: urlToHostname(event.onlineAddress),
          })
        "
        >{{ simpleURL(event.onlineAddress) }}</a
      >
    </event-metadata-block>
    <event-metadata-block
      v-for="extra in extraMetadata"
      :title="extra.title || extra.label"
      :icon="extra.icon"
      :key="extra.key"
    >
      <span
        v-if="
          ((extra.type == EventMetadataType.STRING &&
            extra.keyType == EventMetadataKeyType.CHOICE) ||
            extra.type === EventMetadataType.BOOLEAN) &&
          extra.choices &&
          extra.choices[extra.value]
        "
      >
        {{ extra.choices[extra.value] }}
      </span>
      <a
        v-else-if="
          extra.type == EventMetadataType.STRING &&
          extra.keyType == EventMetadataKeyType.URL
        "
        target="_blank"
        rel="noopener noreferrer ugc"
        :href="extra.value"
        :title="
          $t('View page on {hostname} (in a new window)', {
            hostname: urlToHostname(extra.value),
          })
        "
        >{{ simpleURL(extra.value) }}</a
      >
      <a
        v-else-if="
          extra.type == EventMetadataType.STRING &&
          extra.keyType == EventMetadataKeyType.HANDLE
        "
        target="_blank"
        rel="noopener noreferrer ugc"
        :href="accountURL(extra)"
        :title="
          $t('View account on {hostname} (in a new window)', {
            hostname: urlToHostname(accountURL(extra)),
          })
        "
        >{{ extra.value }}</a
      >
      <span v-else>{{ extra.value }}</span>
    </event-metadata-block>
    <b-modal
      class="map-modal"
      v-if="physicalAddress && physicalAddress.geom"
      :active.sync="showMap"
      has-modal-card
      full-screen
    >
      <div class="modal-card">
        <header class="modal-card-head">
          <button type="button" class="delete" @click="showMap = false" />
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
    </b-modal>
  </div>
</template>
<script lang="ts">
import { Address } from "@/types/address.model";
import { IConfig } from "@/types/config.model";
import {
  EventMetadataKeyType,
  EventMetadataType,
  RoutingTransportationType,
  RoutingType,
} from "@/types/enums";
import { IEvent } from "@/types/event.model";
import { PropType } from "vue";
import { Component, Prop, Vue } from "vue-property-decorator";
import RouteName from "../../router/name";
import { usernameWithDomain } from "../../types/actor";
import EventMetadataBlock from "./EventMetadataBlock.vue";
import EventFullDate from "./EventFullDate.vue";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import ActorCard from "../../components/Account/ActorCard.vue";
import {
  IEventMetadata,
  IEventMetadataDescription,
} from "@/types/event-metadata";
import { eventMetaDataList } from "../../services/EventMetadata";

@Component({
  components: {
    EventMetadataBlock,
    EventFullDate,
    PopoverActorCard,
    ActorCard,
    "map-leaflet": () =>
      import(/* webpackChunkName: "map" */ "../../components/Map.vue"),
  },
})
export default class EventMetadataSidebar extends Vue {
  @Prop({ type: Object as PropType<IEvent>, required: true }) event!: IEvent;
  @Prop({ type: Object as PropType<IConfig>, required: true }) config!: IConfig;

  showMap = false;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  eventMetaDataList = eventMetaDataList;

  EventMetadataType = EventMetadataType;
  EventMetadataKeyType = EventMetadataKeyType;

  RoutingParamType = {
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

  get physicalAddress(): Address | null {
    if (!this.event.physicalAddress) return null;

    return new Address(this.event.physicalAddress);
  }

  get extraMetadata(): IEventMetadata[] {
    return this.event.metadata.map((val) => {
      const def = eventMetaDataList.find((dat) => dat.key === val.key);
      return {
        ...def,
        ...val,
      };
    });
  }

  makeNavigationPath(
    transportationType: RoutingTransportationType
  ): string | undefined {
    const geometry = this.physicalAddress?.geom;
    if (geometry) {
      const routingType = this.config.maps.routing.type;
      /**
       * build urls to routing map
       */
      if (!this.RoutingParamType[routingType][transportationType]) {
        return;
      }

      const urlGeometry = geometry.split(";").reverse().join(",");

      switch (routingType) {
        case RoutingType.GOOGLE_MAPS:
          return `https://maps.google.com/?saddr=Current+Location&daddr=${urlGeometry}&${this.RoutingParamType[routingType][transportationType]}`;
        case RoutingType.OPENSTREETMAP:
        default: {
          const bboxX = geometry.split(";").reverse()[0];
          const bboxY = geometry.split(";").reverse()[1];
          return `https://www.openstreetmap.org/directions?from=&to=${urlGeometry}&${this.RoutingParamType[routingType][transportationType]}#map=14/${bboxX}/${bboxY}`;
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

  urlToHostname(url: string): string | null {
    try {
      return new URL(url).hostname;
    } catch (e) {
      return null;
    }
  }

  simpleURL(url: string): string | null {
    try {
      const uri = new URL(url);
      return `${this.removeWWW(uri.hostname)}${uri.pathname}${uri.search}${
        uri.hash
      }`;
    } catch (e) {
      return null;
    }
  }

  private removeWWW(string: string): string {
    return string.replace(/^www./, "");
  }

  accountURL(extra: IEventMetadataDescription): string | undefined {
    switch (extra.key) {
      case "mz:social:twitter:account": {
        const handle =
          extra.value[0] === "@" ? extra.value.slice(1) : extra.value;
        return `https://twitter.com/${handle}`;
      }
    }
  }
}
</script>
<style lang="scss" scoped>
::v-deep .metadata-organized-by {
  .v-popover.popover .trigger {
    width: 100%;
    .media-content {
      width: calc(100% - 32px - 1rem);
      max-width: 80vw;

      p.has-text-grey-dark {
        text-overflow: ellipsis;
        overflow: hidden;
      }
    }
  }
}

div.address-wrapper {
  display: flex;
  flex: 1;
  flex-wrap: wrap;

  div.address {
    flex: 1;

    .map-show-button {
      cursor: pointer;
    }

    address {
      font-style: normal;
      flex-wrap: wrap;
      display: flex;
      justify-content: flex-start;

      span.addressDescription {
        text-overflow: ellipsis;
        white-space: nowrap;
        flex: 1 0 auto;
        min-width: 100%;
        max-width: 4rem;
        overflow: hidden;
      }

      :not(.addressDescription) {
        flex: 1;
        min-width: 100%;
      }
    }
  }
}

.map-modal {
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
}
</style>
