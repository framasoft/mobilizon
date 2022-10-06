<template>
  <div>
    <event-metadata-block
      v-if="!event.options.isOnline"
      :title="t('Location')"
      :icon="addressPOIInfos?.poiIcon?.icon ?? 'earth'"
    >
      <div class="address-wrapper">
        <span v-if="!physicalAddress">{{ t("No address defined") }}</span>
        <div class="address" v-if="physicalAddress">
          <address-info :address="physicalAddress" />
          <o-button
            variant="text"
            class="map-show-button"
            @click="$emit('showMapModal', true)"
            v-if="physicalAddress.geom"
          >
            {{ t("Show map") }}
          </o-button>
        </div>
      </div>
      <template #icon>
        <o-icon
          v-if="addressPOIInfos?.poiIcon?.icon"
          :icon="addressPOIInfos?.poiIcon?.icon"
          customSize="36"
        />
        <Earth v-else :size="36" />
      </template>
    </event-metadata-block>
    <event-metadata-block :title="t('Date and time')">
      <template #icon>
        <Calendar :size="36" />
      </template>
      <event-full-date
        :beginsOn="event.beginsOn.toString()"
        :show-start-time="event.options.showStartTime"
        :show-end-time="event.options.showEndTime"
        :timezone="event.options.timezone ?? undefined"
        :userTimezone="userTimezone"
        :endsOn="event.endsOn?.toString()"
      />
    </event-metadata-block>
    <event-metadata-block
      class="metadata-organized-by"
      :title="t('Organized by')"
    >
      <router-link
        v-if="event.attributedTo"
        class="hover:underline"
        :to="{
          name: RouteName.GROUP,
          params: {
            preferredUsername: usernameWithDomain(event.attributedTo),
          },
        }"
      >
        <actor-card
          v-if="
            !event.attributedTo || !event.options.hideOrganizerWhenGroupEvent
          "
          :actor="event.attributedTo"
          :inline="true"
        />
      </router-link>
      <actor-card
        v-else-if="event.organizerActor"
        :actor="event.organizerActor"
        :inline="true"
      />
      <actor-card
        :inline="true"
        :actor="contact"
        v-for="contact in event.contacts"
        :key="contact.id"
      />
    </event-metadata-block>
    <event-metadata-block
      v-if="event.onlineAddress && urlToHostname(event.onlineAddress)"
      :title="t('Website')"
    >
      <template #icon>
        <Link :size="36" />
      </template>
      <a
        target="_blank"
        class="underline"
        rel="noopener noreferrer ugc"
        :href="event.onlineAddress"
        :title="
          t('View page on {hostname} (in a new window)', {
            hostname: urlToHostname(event.onlineAddress),
          })
        "
        >{{ simpleURL(event.onlineAddress) }}</a
      >
    </event-metadata-block>
    <event-metadata-block
      v-for="extra in extraMetadata"
      :title="extra.title || extra.label"
      :key="extra.key"
    >
      <template #icon>
        <img
          v-if="extra.icon && extra.icon.substring(0, 7) === 'mz:icon'"
          :src="`/img/${extra.icon.substring(8)}_monochrome.svg`"
          width="36"
          height="36"
          alt=""
        />
        <o-icon v-else-if="extra.icon" :icon="extra.icon" customSize="36" />
        <o-icon v-else customSize="36" icon="help-circle" />
      </template>
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
          t('View page on {hostname} (in a new window)', {
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
          t('View account on {hostname} (in a new window)', {
            hostname: urlToHostname(accountURL(extra)),
          })
        "
        >{{ extra.value }}</a
      >
      <span v-else>{{ extra.value }}</span>
    </event-metadata-block>
  </div>
</template>
<script lang="ts" setup>
import { Address, addressToPoiInfos } from "@/types/address.model";
import { EventMetadataKeyType, EventMetadataType } from "@/types/enums";
import { IEvent } from "@/types/event.model";
import { computed } from "vue";
import RouteName from "../../router/name";
import { usernameWithDomain } from "../../types/actor";
import EventMetadataBlock from "./EventMetadataBlock.vue";
import EventFullDate from "./EventFullDate.vue";
import ActorCard from "../../components/Account/ActorCard.vue";
import AddressInfo from "../../components/Address/AddressInfo.vue";
import { IEventMetadataDescription } from "@/types/event-metadata";
import { eventMetaDataList } from "../../services/EventMetadata";
import { IUser } from "@/types/current-user.model";
import { useI18n } from "vue-i18n";
import Earth from "vue-material-design-icons/Earth.vue";
import Calendar from "vue-material-design-icons/Calendar.vue";
import Link from "vue-material-design-icons/Link.vue";

const props = withDefaults(
  defineProps<{
    event: IEvent;
    user: IUser | undefined;
    showMap?: boolean;
  }>(),
  { showMap: false }
);

const { t } = useI18n({ useScope: "global" });

const physicalAddress = computed((): Address | null => {
  if (!props.event.physicalAddress) return null;

  return new Address(props.event.physicalAddress);
});

const addressPOIInfos = computed(() => {
  if (!props.event.physicalAddress) return null;
  return addressToPoiInfos(props.event.physicalAddress);
});

const extraMetadata = computed((): IEventMetadataDescription[] => {
  return props.event.metadata.map((val) => {
    const def = eventMetaDataList.find((dat) => dat.key === val.key);
    return {
      ...def,
      ...val,
    };
  });
});

const urlToHostname = (url: string | undefined): string | null => {
  if (!url) return null;
  try {
    return new URL(url).hostname;
  } catch (e) {
    return null;
  }
};

const simpleURL = (url: string): string | null => {
  try {
    const uri = new URL(url);
    return `${removeWWW(uri.hostname)}${uri.pathname}${uri.search}${uri.hash}`;
  } catch (e) {
    return null;
  }
};

const removeWWW = (string: string): string => {
  return string.replace(/^www./, "");
};

const accountURL = (extra: IEventMetadataDescription): string | undefined => {
  switch (extra.key) {
    case "mz:social:twitter:account": {
      const handle =
        extra.value[0] === "@" ? extra.value.slice(1) : extra.value;
      return `https://twitter.com/${handle}`;
    }
  }
};

const userTimezone = computed((): string | undefined => {
  return props.user?.settings?.timezone;
});
</script>
<style lang="scss" scoped>
:deep(.metadata-organized-by) {
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
