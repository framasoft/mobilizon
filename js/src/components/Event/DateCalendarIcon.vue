<template>
    <time class="datetime-container" :datetime="dateObj.getUTCSeconds()">
        <span class="month">{{ month }}</span>
        <span class="day">{{ day }}</span>
    </time>
</template>
<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';

@Component
export default class DateCalendarIcon extends Vue {
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
  time.datetime-container {
    background: #f6f7f8;
    border: 1px solid rgba(46,62,72,.12);
    border-radius: 8px;
    display: flex;
    flex-direction: column;
    justify-content: center;
    /*height: 50px;*/
    width: 48px;
    padding: 8px;
    text-align: center;

    span {
      display: block;

      &.month {
        color: #fa3e3e;
        padding: 2px 0;
        font-size: 12px;
        line-height: 12px;
        text-transform: uppercase;
      }

      &.day {
        font-weight: 300;
        font-size: 20px;
        line-height: 20px;
      }
    }
  }
</style>
