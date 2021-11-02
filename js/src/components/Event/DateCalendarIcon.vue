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
  <div
    class="datetime-container"
    :class="{ small }"
    :style="`--small: ${smallStyle}`"
  >
    <div class="datetime-container-header" />
    <div class="datetime-container-content">
      <time :datetime="dateObj.toISOString()" class="day">{{ day }}</time>
      <time :datetime="dateObj.toISOString()" class="month">{{ month }}</time>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";

@Component
export default class DateCalendarIcon extends Vue {
  /**
   * `date` can be a string or an actual date object.
   */
  @Prop({ required: true }) date!: string;
  @Prop({ required: false, default: false }) small!: boolean;

  get dateObj(): Date {
    return new Date(this.$props.date);
  }

  get month(): string {
    return this.dateObj.toLocaleString(undefined, { month: "short" });
  }

  get day(): string {
    return this.dateObj.toLocaleString(undefined, { day: "numeric" });
  }
  get smallStyle(): string {
    return this.small ? "1.2" : "2";
  }
}
</script>

<style lang="scss" scoped>
div.datetime-container {
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  text-align: center;
  overflow-y: hidden;
  overflow-x: hidden;
  align-items: stretch;
  width: calc(40px * var(--small));
  box-shadow: 0 0 12px rgba(0, 0, 0, 0.2);
  height: calc(40px * var(--small));
  background: #fff;

  .datetime-container-header {
    height: calc(10px * var(--small));
    background: #f3425f;
  }
  .datetime-container-content {
    height: calc(30px * var(--small));
  }

  time {
    display: block;
    font-weight: 600;
    color: $violet-3;

    &.month {
      padding: 2px 0;
      font-size: 12px;
      line-height: 12px;
      text-transform: uppercase;
    }

    &.day {
      font-size: calc(1rem * var(--small));
      line-height: calc(1rem * var(--small));
    }
  }
}
</style>
