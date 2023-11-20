<template>
  <div
    class="datetime-container flex flex-col rounded-lg text-center justify-center overflow-hidden items-stretch bg-white dark:bg-gray-700 text-violet-3 dark:text-white"
    :class="{ small }"
    :style="`--small: ${smallStyle}`"
  >
    <div class="datetime-container-header" />
    <div class="datetime-container-content">
      <time :datetime="dateObj.toISOString()" class="day block font-semibold">{{
        day
      }}</time>
      <time
        :datetime="dateObj.toISOString()"
        class="month font-semibold block uppercase py-1 px-0"
        >{{ month }}</time
      >
    </div>
  </div>
</template>
<script lang="ts" setup>
import { computed } from "vue";

const props = withDefaults(
  defineProps<{
    date: string;
    small?: boolean;
  }>(),
  { small: false }
);

const dateObj = computed<Date>(() => new Date(props.date));

const month = computed<string>(() =>
  dateObj.value.toLocaleString(undefined, { month: "short" })
);

const day = computed<string>(() =>
  dateObj.value.toLocaleString(undefined, { day: "numeric" })
);

const smallStyle = computed<string>(() => (props.small ? "1.2" : "2"));
</script>

<style lang="scss" scoped>
div.datetime-container {
  width: calc(40px * var(--small));
  box-shadow: 0 0 12px rgba(0, 0, 0, 0.2);
  height: calc(40px * var(--small));

  .datetime-container-header {
    height: calc(10px * var(--small));
    background: #f3425f;
  }
  .datetime-container-content {
    height: calc(30px * var(--small));
  }

  time {
    &.month {
      font-size: 12px;
      line-height: 12px;
    }

    &.day {
      font-size: calc(1rem * var(--small));
      line-height: calc(1rem * var(--small));
    }
  }
}
</style>
