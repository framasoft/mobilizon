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
    <span v-if="!endsOn">{{ beginsOn | formatDateTimeString }}</span>
    <span v-else-if="isSameDay()">
        {{ $t('On {date} from {startTime} to {endTime}', {date: formatDate(beginsOn), startTime: formatTime(beginsOn), endTime: formatTime(endsOn)}) }}
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
