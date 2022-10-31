<template>
  <address dir="auto">
    <o-icon
      v-if="showIcon"
      :icon="poiInfos?.poiIcon.icon"
      size="medium"
      class="icon"
    />
    <p>
      <span
        class="addressDescription"
        :title="poiInfos.name"
        v-if="poiInfos?.name"
      >
        {{ poiInfos.name }}
      </span>
      <br v-if="poiInfos?.name" />
      <span>
        {{ poiInfos?.alternativeName }}
      </span>
      <br />
      <small
        v-if="
          userTimezoneDifferent &&
          longShortTimezoneNamesDifferent &&
          timezoneLongNameValid
        "
      >
        🌐
        {{
          $t("{timezoneLongName} ({timezoneShortName})", {
            timezoneLongName,
            timezoneShortName,
          })
        }}
      </small>
      <small v-else-if="userTimezoneDifferent" class="">
        🌐 {{ timezoneShortName }}
      </small>
    </p>
  </address>
</template>
<script lang="ts" setup>
import { addressToPoiInfos, IAddress } from "@/types/address.model";
import { computed } from "vue";

const props = withDefaults(
  defineProps<{
    address: IAddress;
    showIcon?: boolean;
    showTimezone?: boolean;
    userTimezone?: string;
  }>(),
  {
    showIcon: false,
    showTimezone: false,
  }
);

const poiInfos = computed(() => addressToPoiInfos(props.address));

const userTimezoneDifferent = computed((): boolean => {
  return (
    props.userTimezone != undefined &&
    props.address.timezone != undefined &&
    props.userTimezone !== props.address.timezone
  );
});

const longShortTimezoneNamesDifferent = computed((): boolean => {
  return (
    timezoneLongName.value != undefined &&
    timezoneShortName.value != undefined &&
    timezoneLongName.value !== timezoneShortName.value
  );
});

const timezoneLongName = computed((): string | undefined => {
  return timezoneName("long");
});

const timezoneShortName = computed((): string | undefined => {
  return timezoneName("short");
});

const timezoneLongNameValid = computed((): boolean => {
  return (
    timezoneLongName.value != undefined && !timezoneLongName.value.match(/UTC/)
  );
});

const timezoneName = (format: "long" | "short"): string | undefined => {
  return extractTimezone(
    new Intl.DateTimeFormat(undefined, {
      timeZoneName: format,
      timeZone: props.address.timezone,
    }).formatToParts()
  );
};

const extractTimezone = (
  parts: Intl.DateTimeFormatPart[]
): string | undefined => {
  return parts.find((part) => part.type === "timeZoneName")?.value;
};
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
address {
  font-style: normal;
  display: flex;
  justify-content: flex-start;

  span.addressDescription {
    text-overflow: ellipsis;
    overflow: hidden;
  }

  span.icon {
    @include padding-right(1rem);
  }
}
</style>
