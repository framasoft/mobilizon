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
            @click="$emit('showMapModal', true)"
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
        :timezone="event.options.timezone"
        :userTimezone="userTimezone"
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
  </div>
</template>
<script lang="ts">
import { Address } from "@/types/address.model";
import { IConfig } from "@/types/config.model";
import { EventMetadataKeyType, EventMetadataType } from "@/types/enums";
import { IEvent } from "@/types/event.model";
import { PropType } from "vue";
import { Component, Prop, Vue } from "vue-property-decorator";
import RouteName from "../../router/name";
import { usernameWithDomain } from "../../types/actor";
import EventMetadataBlock from "./EventMetadataBlock.vue";
import EventFullDate from "./EventFullDate.vue";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import ActorCard from "../../components/Account/ActorCard.vue";
import AddressInfo from "../../components/Address/AddressInfo.vue";
import {
  IEventMetadata,
  IEventMetadataDescription,
} from "@/types/event-metadata";
import { eventMetaDataList } from "../../services/EventMetadata";
import { IUser } from "@/types/current-user.model";

@Component({
  components: {
    EventMetadataBlock,
    EventFullDate,
    PopoverActorCard,
    ActorCard,
    AddressInfo,
  },
})
export default class EventMetadataSidebar extends Vue {
  @Prop({ type: Object as PropType<IEvent>, required: true }) event!: IEvent;
  @Prop({ type: Object as PropType<IConfig>, required: true }) config!: IConfig;
  @Prop({ required: true }) user!: IUser | undefined;
  @Prop({ required: false, default: false }) showMap!: boolean;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  eventMetaDataList = eventMetaDataList;

  EventMetadataType = EventMetadataType;
  EventMetadataKeyType = EventMetadataKeyType;

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

  get userTimezone(): string | undefined {
    return this.user?.settings?.timezone;
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
  }
}
</style>
