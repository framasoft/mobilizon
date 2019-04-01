<template>
    <span class="container">
        <span class="month">{{ month }}</span>
        <span class="day">{{ day }}</span>
    </span>
</template>
<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';

@Component
export default class DateComponent extends Vue {
  @Prop({ required: true }) date!: string;

  get dateObj() {
      return new Date(this.$props.date);
  }

  get month() {
    return this.dateObj.toLocaleString(undefined, { month: 'short' });
  }

  get day() {
    return this.dateObj.toLocaleString(undefined, { day: 'numeric' });
  }
}
</script>

<style lang="scss" scoped>
  .container {
    display: inline-flex;
    padding: 2px 0;
    width: 40px;
    background: #fff;

    span {
      flex: 0;
      flex-direction: column;
      text-align: center;

      &.month {
        color: #fa3e3e;
        padding: 2px 0;
        font-size: 12px;
        line-height: 12px;
      }

      &.day {
        font-weight: 300;
        font-size: 20px;
        line-height: 20px;
      }
    }
  }
</style>
