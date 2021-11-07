<template>
  <address dir="auto">
    <b-icon
      v-if="showIcon"
      :icon="address.poiInfos.poiIcon.icon"
      size="is-medium"
      class="icon"
    />
    <p>
      <span
        class="addressDescription"
        :title="address.poiInfos.name"
        v-if="address.poiInfos.name"
      >
        {{ address.poiInfos.name }}
      </span>
      <br v-if="address.poiInfos.name" />
      <span class="has-text-grey-dark">
        {{ address.poiInfos.alternativeName }}
      </span>
      <br />
      <small
        v-if="
          userTimezoneDifferent &&
          longShortTimezoneNamesDifferent &&
          timezoneLongNameValid
        "
        class="has-text-grey-dark"
      >
        🌐
        {{
          $t("{timezoneLongName} ({timezoneShortName})", {
            timezoneLongName,
            timezoneShortName,
          })
        }}
      </small>
      <small v-else-if="userTimezoneDifferent" class="has-text-grey-dark">
        🌐 {{ timezoneShortName }}
      </small>
    </p>
  </address>
</template>
<script lang="ts">
import { IAddress } from "@/types/address.model";
import { PropType } from "vue";
import { Component, Prop, Vue } from "vue-property-decorator";

@Component
export default class AddressInfo extends Vue {
  @Prop({ required: true, type: Object as PropType<IAddress> })
  address!: IAddress;

  @Prop({ required: false, default: false, type: Boolean }) showIcon!: boolean;
  @Prop({ required: false, default: false, type: Boolean })
  showTimezone!: boolean;
  @Prop({ required: false, type: String }) userTimezone!: string;

  get userTimezoneDifferent(): boolean {
    return (
      this.userTimezone != undefined &&
      this.address.timezone != undefined &&
      this.userTimezone !== this.address.timezone
    );
  }

  get longShortTimezoneNamesDifferent(): boolean {
    return (
      this.timezoneLongName != undefined &&
      this.timezoneShortName != undefined &&
      this.timezoneLongName !== this.timezoneShortName
    );
  }

  get timezoneLongName(): string | undefined {
    return this.timezoneName("long");
  }

  get timezoneShortName(): string | undefined {
    return this.timezoneName("short");
  }

  get timezoneLongNameValid(): boolean {
    return (
      this.timezoneLongName != undefined && !this.timezoneLongName.match(/UTC/)
    );
  }

  private timezoneName(format: "long" | "short"): string | undefined {
    return this.extractTimezone(
      new Intl.DateTimeFormat(undefined, {
        timeZoneName: format,
        timeZone: this.address.timezone,
      }).formatToParts()
    );
  }

  private extractTimezone(
    parts: Intl.DateTimeFormatPart[]
  ): string | undefined {
    return parts.find((part) => part.type === "timeZoneName")?.value;
  }
}
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
address {
  font-style: normal;
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

  span.icon {
    @include padding-right(1rem);
  }
}
</style>
