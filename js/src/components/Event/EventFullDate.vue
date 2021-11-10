<docs>
#### Give a translated and localized text that give the starting and ending datetime for an event.

##### Start date with no ending
```vue
<EventFullDate beginsOn="2015-10-06T18:41:11.720Z" />
```

##### Start date with an ending the same day
```vue
<EventFullDate beginsOn="2015-10-06T18:41:11.720Z" endsOn="2015-10-06T20:41:11.720Z" />
```

##### Start date with an ending on a different day
```vue
<EventFullDate beginsOn="2015-10-06T18:41:11.720Z" endsOn="2032-10-06T18:41:11.720Z" />
```
</docs>

<template>
  <p v-if="!endsOn">
    <span>{{
      formatDateTimeString(beginsOn, timezoneToShow, showStartTime)
    }}</span>
    <br />
    <b-switch
      size="is-small"
      v-model="showLocalTimezone"
      v-if="differentFromUserTimezone"
    >
      {{ singleTimeZone }}
    </b-switch>
  </p>
  <p v-else-if="isSameDay() && showStartTime && showEndTime">
    <span>{{
      $t("On {date} from {startTime} to {endTime}", {
        date: formatDate(beginsOn),
        startTime: formatTime(beginsOn, timezoneToShow),
        endTime: formatTime(endsOn, timezoneToShow),
      })
    }}</span>
    <br />
    <b-switch
      size="is-small"
      v-model="showLocalTimezone"
      v-if="differentFromUserTimezone"
    >
      {{ singleTimeZone }}
    </b-switch>
  </p>
  <p v-else-if="isSameDay() && showStartTime && !showEndTime">
    {{
      $t("On {date} starting at {startTime}", {
        date: formatDate(beginsOn),
        startTime: formatTime(beginsOn),
      })
    }}
  </p>
  <p v-else-if="isSameDay()">
    {{ $t("On {date}", { date: formatDate(beginsOn) }) }}
  </p>
  <p v-else-if="endsOn && showStartTime && showEndTime">
    <span>
      {{
        $t(
          "From the {startDate} at {startTime} to the {endDate} at {endTime}",
          {
            startDate: formatDate(beginsOn),
            startTime: formatTime(beginsOn, timezoneToShow),
            endDate: formatDate(endsOn),
            endTime: formatTime(endsOn, timezoneToShow),
          }
        )
      }}
    </span>
    <br />
    <b-switch
      size="is-small"
      v-model="showLocalTimezone"
      v-if="differentFromUserTimezone"
    >
      {{ multipleTimeZones }}
    </b-switch>
  </p>
  <p v-else-if="endsOn && showStartTime">
    <span>
      {{
        $t("From the {startDate} at {startTime} to the {endDate}", {
          startDate: formatDate(beginsOn),
          startTime: formatTime(beginsOn, timezoneToShow),
          endDate: formatDate(endsOn),
        })
      }}
    </span>
    <br />
    <b-switch
      size="is-small"
      v-model="showLocalTimezone"
      v-if="differentFromUserTimezone"
    >
      {{ singleTimeZone }}
    </b-switch>
  </p>
  <p v-else-if="endsOn">
    {{
      $t("From the {startDate} to the {endDate}", {
        startDate: formatDate(beginsOn),
        endDate: formatDate(endsOn),
      })
    }}
  </p>
</template>
<script lang="ts">
import { getTimezoneOffset } from "date-fns-tz";
import { Component, Prop, Vue } from "vue-property-decorator";

@Component
export default class EventFullDate extends Vue {
  @Prop({ required: true }) beginsOn!: string;

  @Prop({ required: false }) endsOn!: string;

  @Prop({ required: false, default: true }) showStartTime!: boolean;

  @Prop({ required: false, default: true }) showEndTime!: boolean;

  @Prop({ required: false }) timezone!: string;

  @Prop({ required: false }) userTimezone!: string;

  showLocalTimezone = true;

  get timezoneToShow(): string {
    if (this.showLocalTimezone) {
      return this.timezone;
    }
    return this.userActualTimezone;
  }

  get userActualTimezone(): string {
    if (this.userTimezone) {
      return this.userTimezone;
    }
    return Intl.DateTimeFormat().resolvedOptions().timeZone;
  }

  formatDate(value: Date): string | undefined {
    if (!this.$options.filters) return undefined;
    return this.$options.filters.formatDateString(value);
  }

  formatTime(value: Date, timezone: string): string | undefined {
    if (!this.$options.filters) return undefined;
    return this.$options.filters.formatTimeString(value, timezone || undefined);
  }

  formatDateTimeString(
    value: Date,
    timezone: string,
    showTime: boolean
  ): string | undefined {
    if (!this.$options.filters) return undefined;
    return this.$options.filters.formatDateTimeString(
      value,
      timezone,
      showTime
    );
  }

  isSameDay(): boolean {
    const sameDay =
      new Date(this.beginsOn).toDateString() ===
      new Date(this.endsOn).toDateString();
    return this.endsOn !== undefined && sameDay;
  }

  get differentFromUserTimezone(): boolean {
    return (
      !!this.timezone &&
      !!this.userActualTimezone &&
      getTimezoneOffset(this.timezone) !==
        getTimezoneOffset(this.userActualTimezone) &&
      this.timezone !== this.userActualTimezone
    );
  }

  get singleTimeZone(): string {
    if (this.showLocalTimezone) {
      return this.$t("Local time ({timezone})", {
        timezone: this.timezoneToShow,
      }) as string;
    }
    return this.$t("Time in your timezone ({timezone})", {
      timezone: this.timezoneToShow,
    }) as string;
  }

  get multipleTimeZones(): string {
    if (this.showLocalTimezone) {
      return this.$t("Local time ({timezone})", {
        timezone: this.timezoneToShow,
      }) as string;
    }
    return this.$t("Times in your timezone ({timezone})", {
      timezone: this.timezoneToShow,
    }) as string;
  }
}
</script>
