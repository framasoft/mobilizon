<docs>
### Example
```vue
  <DateCalendarIcon date="2019-10-05T18:41:11.720Z" />
```

```vue
  <DateCalendarIcon
    :date="new Date()"
  />
```
</docs>

<template>
  <time class="datetime-container" :datetime="dateObj.getUTCSeconds()">
    <span class="month">{{ month }}</span>
    <span class="day">{{ day }}</span>
  </time>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";

@Component
export default class DateCalendarIcon extends Vue {
  /**
   * `date` can be a string or an actual date object.
   */
  @Prop({ required: true }) date!: string;

  get dateObj(): Date {
    return new Date(this.$props.date);
  }

  get month(): string {
    return this.dateObj.toLocaleString(undefined, { month: "short" });
  }

  get day(): string {
    return this.dateObj.toLocaleString(undefined, { day: "numeric" });
  }
}
</script>

<style lang="scss" scoped>
time.datetime-container {
  background: $backgrounds;
  border: 1px solid $borders;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  /*height: 50px;*/
  width: 50px;
  padding: 8px;
  text-align: center;

  span {
    display: block;
    font-weight: 600;

    &.month {
      color: $danger;
      padding: 2px 0;
      font-size: 12px;
      line-height: 12px;
      text-transform: uppercase;
    }

    &.day {
      color: $violet-3;
      font-size: 20px;
      line-height: 20px;
    }
  }
}
</style>
