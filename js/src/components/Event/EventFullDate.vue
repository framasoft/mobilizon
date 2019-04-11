<template>
    <translate
            v-if="!endsOn"
           :translate-params="{date: formatDate(beginsOn), time: formatTime(beginsOn)}"
    >The %{ date } at %{ time }</translate>
    <translate
            v-else-if="isSameDay()"
            :translate-params="{date: formatDate(beginsOn), startTime: formatTime(beginsOn), endTime: formatTime(endsOn)}"
    >The %{ date } from %{ startTime } to %{ endTime }</translate>
    <translate
            v-else-if="endsOn"
            :translate-params="{startDate: formatDate(beginsOn), startTime: formatTime(beginsOn), endDate: formatDate(endsOn), endTime: formatTime(endsOn)}"
    >From the %{ startDate } at %{ startTime } to the %{ endDate } at %{ endTime }</translate>
</template>
<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';

@Component
export default class EventFullDate extends Vue {
  @Prop({ required: true }) beginsOn!: string;
  @Prop({ required: false }) endsOn!: string;

  formatDate(value) {
    return value ? new Date(value).toLocaleString(undefined, { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }) : null;
  }

  formatTime(value) {
    return value ? new Date(value).toLocaleTimeString(undefined, { hour: 'numeric', minute: 'numeric' }) : null;
  }

  isSameDay() {
    const sameDay = ((new Date(this.beginsOn)).toDateString()) === ((new Date(this.endsOn)).toDateString());
    return this.endsOn && sameDay;
  }
}
</script>
