<template>
  <div
    class="starttime-container flex flex-col rounded-lg text-center justify-center overflow-hidden items-stretch bg-white dark:bg-gray-700 text-violet-3 dark:text-white"
    :class="{ small }"
    :style="`--small: ${smallStyle}`"
  >
    <div class="starttime-container-content font-semibold">
      <Clock class="clock-icon" /><time :datetime="dateObj.toISOString()">{{
        time
      }}</time>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { computed } from "vue";
import { useI18n } from "vue-i18n";

import Clock from "vue-material-design-icons/ClockTimeTenOutline.vue";

const { locale } = useI18n({ useScope: "global" });

const localeConverted = locale.replace("_", "-");

const props = withDefaults(
  defineProps<{
    date: string;
    small?: boolean;
  }>(),
  { small: false }
);

const dateObj = computed<Date>(() => new Date(props.date));

const time = computed<string>(() =>
  dateObj.value.toLocaleTimeString(localeConverted, {
    hour: "2-digit",
    minute: "2-digit",
  })
);

const smallStyle = computed<string>(() => (props.small ? "0.9" : "2"));
</script>

<style lang="scss" scoped>
div.starttime-container {
  width: auto;
  box-shadow: 0 0 12px rgba(0, 0, 0, 0.2);
  padding: 0.25rem 0.25rem;
  font-size: calc(1rem * var(--small));
}

.clock-icon {
  vertical-align: middle;
  padding-right: 0.2rem;
  display: inline-block;
}
</style>
