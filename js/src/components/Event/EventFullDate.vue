<template>
    <span v-if="!endsOn">{{ beginsOn | formatDateTimeString }}</span>
    <span v-else-if="isSameDay()">
        {{ $t('The {date} from {startTime} to {endTime}', {date: formatDate(beginsOn), startTime: formatTime(beginsOn), endTime: formatTime(endsOn)}) }}
    </span>
    <span v-else-if="endsOn">
        {{ $t('From the {startDate} at {startTime} to the {endDate} at {endTime}',
        {startDate: formatDate(beginsOn), startTime: formatTime(beginsOn), endDate: formatDate(endsOn), endTime: formatTime(endsOn)}) }}
    </span>
</template>
<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';

@Component
export default class EventFullDate extends Vue {
  @Prop({ required: true }) beginsOn!: string;
  @Prop({ required: false }) endsOn!: string;

  formatDate(value) {
    if (!this.$options.filters) return;
    return this.$options.filters.formatDateString(value);
  }

  formatTime(value) {
    if (!this.$options.filters) return;
    return this.$options.filters.formatTimeString(value);
  }

  isSameDay() {
    const sameDay = ((new Date(this.beginsOn)).toDateString()) === ((new Date(this.endsOn)).toDateString());
    return this.endsOn && sameDay;
  }
}
</script>
