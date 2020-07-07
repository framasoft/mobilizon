<docs>
### Datetime Picker

> We're wrapping the Buefy datepicker & an input

### Defaults
- step: 10

### Example
```vue
  <DateTimePicker :value="new Date()" />
```
</docs>
<template>
  <div class="field is-horizontal">
    <div class="field-label is-normal">
      <label class="label">{{ label }}</label>
    </div>
    <div class="field-body">
      <div class="field is-narrow is-grouped calendar-picker">
        <b-datepicker
          :day-names="localeShortWeekDayNamesProxy"
          :month-names="localeMonthNamesProxy"
          :first-day-of-week="parseInt($t('firstDayOfWeek'), 10)"
          :min-date="minDatetime"
          :max-date="maxDatetime"
          v-model="dateWithTime"
          :placeholder="$t('Click to select')"
          :years-range="[-2, 10]"
          icon="calendar"
          class="is-narrow"
        />
        <b-timepicker
          placeholder="Type or select a time..."
          icon="clock"
          v-model="dateWithTime"
          :min-time="minTime"
          :max-time="maxTime"
          size="is-small"
          inline
        >
        </b-timepicker>
      </div>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import { localeMonthNames, localeShortWeekDayNames } from "@/utils/datetime";

@Component
export default class DateTimePicker extends Vue {
  /**
   * @model
   * The DateTime value
   */
  @Prop({ required: true, type: Date, default: () => new Date() }) value!: Date;

  /**
   * What's shown besides the picker
   */
  @Prop({ required: false, type: String, default: "Datetime" }) label!: string;

  /**
   * The step for the time input
   */
  @Prop({ required: false, type: Number, default: 1 }) step!: number;

  /**
   * Earliest date available for selection
   */
  @Prop({ required: false, type: Date, default: null }) minDatetime!: Date;

  /**
   * Latest date available for selection
   */
  @Prop({ required: false, type: Date, default: null }) maxDatetime!: Date;

  dateWithTime: Date = this.value;

  localeShortWeekDayNamesProxy = localeShortWeekDayNames();

  localeMonthNamesProxy = localeMonthNames();

  @Watch("value")
  updateValue() {
    this.dateWithTime = this.value;
  }

  @Watch("dateWithTime")
  updateDateWithTimeWatcher() {
    this.updateDateTime();
  }

  updateDateTime() {
    /**
     * Returns the updated date
     *
     * @type {Date}
     */
    this.$emit("input", this.dateWithTime);
  }

  get minTime(): Date | null {
    if (this.minDatetime && this.datesAreOnSameDay(this.dateWithTime, this.minDatetime)) {
      return this.minDatetime;
    }
    return null;
  }

  get maxTime(): Date | null {
    if (this.maxDatetime && this.datesAreOnSameDay(this.dateWithTime, this.maxDatetime)) {
      return this.maxDatetime;
    }
    return null;
  }

  private datesAreOnSameDay(first: Date, second: Date): boolean {
    return (
      first.getFullYear() === second.getFullYear() &&
      first.getMonth() === second.getMonth() &&
      first.getDate() === second.getDate()
    );
  }
}
</script>

<style lang="scss" scoped>
.timepicker {
  /deep/ .dropdown-content {
    padding: 0;
  }
}

.calendar-picker {
  /deep/ .dropdown-menu {
    z-index: 200;
  }
}
</style>
