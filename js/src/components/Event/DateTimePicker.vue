<template>
    <b-field grouped horizontal :label="label">
        <b-datepicker expanded v-model="date" :placeholder="$gettext('Click to select')" icon="calendar"></b-datepicker>
        <b-input expanded type="time" required v-model="time" />
    </b-field>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
@Component({})
export default class DateTimePicker extends Vue {
  @Prop({ required: true, type: Date }) value!: Date;
  @Prop({ required: false, type: String, default: 'Datetime' }) label!: string;
  @Prop({ required: false, type: Number, default: 1 }) step!: number;

  date: Date = this.value;
  time: string = '00:00';

  created() {
    let minutes = this.value.getHours() * 60 + this.value.getMinutes();
    minutes = Math.ceil(minutes / this.step) * this.step;

    this.time = [Math.floor(minutes / 60), minutes % 60].map((v) => { return v < 10 ? `0${v}` : v; }).join(':');
  }

  @Watch('time')
  updateDateTime(time) {
    const [hours, minutes] = time.split(':', 2);
    this.value.setHours(hours);
    this.value.setMinutes(minutes);
    this.$emit('input', this.value);
  }
}
</script>
