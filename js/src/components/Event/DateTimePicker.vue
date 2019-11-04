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
            <div class="field is-narrow is-grouped">
                <b-datepicker
                        :day-names="localeShortWeekDayNamesProxy"
                        :month-names="localeMonthNamesProxy"
                        :first-day-of-week="parseInt($t('firstDayOfWeek'), 10)"
                        :min-date="minDate"
                        v-model="dateWithoutTime"
                        :placeholder="$t('Click to select')"
                        icon="calendar"
                        class="is-narrow"
                />
                <b-timepicker
                        placeholder="Type or select a time..."
                        icon="clock"
                        v-model="dateWithTime"
                        size="is-small"
                        inline>
                </b-timepicker>
            </div>
        </div>
    </div>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import { localeMonthNames, localeShortWeekDayNames } from '@/utils/datetime';

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
  @Prop({ required: false, type: String, default: 'Datetime' }) label!: string;

  /**
   * The step for the time input
   */
  @Prop({ required: false, type: Number, default: 1 }) step!: number;

    /**
     * Earliest date available for selection
     */
  @Prop({ required: false, type: Date, default: null }) minDate!: Date;

  dateWithoutTime: Date = this.value;
  dateWithTime: Date = this.dateWithoutTime;

  localeShortWeekDayNamesProxy = localeShortWeekDayNames();
  localeMonthNamesProxy = localeMonthNames();

  @Watch('value')
  updateValue() {
    this.dateWithoutTime = this.value;
    this.dateWithTime = this.dateWithoutTime;
  }

  @Watch('dateWithoutTime')
  updateDateWithoutTimeWatcher() {
    this.updateDateTime();
  }

  @Watch('dateWithTime')
  updateDateWithTimeWatcher() {
    this.updateDateTime();
  }

  updateDateTime() {
    /**
     * Returns the updated date
     *
     * @type {Date}
     */
    this.dateWithoutTime.setHours(this.dateWithTime.getHours());
    this.dateWithoutTime.setMinutes(this.dateWithTime.getMinutes());
    this.$emit('input', this.dateWithoutTime);
  }
}
</script>

<style lang="scss" scoped>
    .timepicker {
        /deep/ .dropdown-content {
            padding: 0;
        }
    }
</style>
