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
    <b-field grouped horizontal :label="label">
        <b-datepicker expanded v-model="date" :placeholder="$t('Click to select')" icon="calendar"></b-datepicker>
        <b-input expanded type="time" required v-model="time" />
    </b-field>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
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

  date: Date = this.value;
  time: string = '00:00';

  mounted() {
    this.convertTime();
  }

  convertTime() {
    let minutes = this.date.getHours() * 60 + this.date.getMinutes();
    minutes = Math.ceil(minutes / this.step) * this.step;

    this.time = [Math.floor(minutes / 60), minutes % 60].map((v) => { return v < 10 ? `0${v}` : v; }).join(':');
  }

  @Watch('time')
  updateTime(time: string) {
    const [hours, minutes] = time.split(':', 2);
    this.date.setHours(parseInt(hours, 10));
    this.date.setMinutes(parseInt(minutes, 10));
    this.updateDateTime();
  }

  @Watch('date')
  updateDate() {
    this.updateTime(this.time);
  }

  @Watch('value')
  updateValue() {
    this.date = this.value;
    this.convertTime();
  }

  updateDateTime() {
    /**
     * Returns the updated date
     *
     * @type {Date}
     */
    this.$emit('input', this.date);
  }
}
</script>
