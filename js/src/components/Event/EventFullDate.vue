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
  <span v-if="!endsOn">{{
    beginsOn | formatDateTimeString(showStartTime)
  }}</span>
  <span v-else-if="isSameDay() && showStartTime && showEndTime">
    {{
      $t("On {date} from {startTime} to {endTime}", {
        date: formatDate(beginsOn),
        startTime: formatTime(beginsOn),
        endTime: formatTime(endsOn),
      })
    }}
  </span>
  <span v-else-if="isSameDay() && !showStartTime && showEndTime">
    {{
      $t("On {date} ending at {endTime}", {
        date: formatDate(beginsOn),
        endTime: formatTime(endsOn),
      })
    }}
  </span>
  <span v-else-if="isSameDay() && showStartTime && !showEndTime">
    {{
      $t("On {date} starting at {startTime}", {
        date: formatDate(beginsOn),
        startTime: formatTime(beginsOn),
      })
    }}
  </span>
  <span v-else-if="isSameDay()">{{
    $t("On {date}", { date: formatDate(beginsOn) })
  }}</span>
  <span v-else-if="endsOn && showStartTime && showEndTime">
    {{
      $t("From the {startDate} at {startTime} to the {endDate} at {endTime}", {
        startDate: formatDate(beginsOn),
        startTime: formatTime(beginsOn),
        endDate: formatDate(endsOn),
        endTime: formatTime(endsOn),
      })
    }}
  </span>
  <span v-else-if="endsOn && showStartTime">
    {{
      $t("From the {startDate} at {startTime} to the {endDate}", {
        startDate: formatDate(beginsOn),
        startTime: formatTime(beginsOn),
        endDate: formatDate(endsOn),
      })
    }}
  </span>
  <span v-else-if="endsOn">
    {{
      $t("From the {startDate} to the {endDate}", {
        startDate: formatDate(beginsOn),
        endDate: formatDate(endsOn),
      })
    }}
  </span>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";

@Component
export default class EventFullDate extends Vue {
  @Prop({ required: true }) beginsOn!: string;

  @Prop({ required: false }) endsOn!: string;

  @Prop({ required: false, default: true }) showStartTime!: boolean;

  @Prop({ required: false, default: true }) showEndTime!: boolean;

  formatDate(value: Date): string | undefined {
    if (!this.$options.filters) return undefined;
    return this.$options.filters.formatDateString(value);
  }

  formatTime(value: Date): string | undefined {
    if (!this.$options.filters) return undefined;
    return this.$options.filters.formatTimeString(value);
  }

  isSameDay(): boolean {
    const sameDay =
      new Date(this.beginsOn).toDateString() ===
      new Date(this.endsOn).toDateString();
    return this.endsOn !== undefined && sameDay;
  }
}
</script>
