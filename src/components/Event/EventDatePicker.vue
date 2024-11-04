<template>
  <input
    type="datetime-local"
    class="rounded"
    v-model="component"
    :min="computeMin"
    @blur="$emit('blur')"
  />
</template>
<script lang="ts" setup>
import { computed } from "vue";

const props = withDefaults(
  defineProps<{
    modelValue: Date;
    min?: Date | undefined;
  }>(),
  {
    min: undefined,
  }
);

const emit = defineEmits(["update:modelValue", "blur"]);

/** Format a Date to 'YYYY-MM-DDTHH:MM' based on local time zone */
const UTCToLocal = (date: Date) => {
  const localDate = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
  return localDate.toISOString().slice(0, 16);
};

const component = computed({
  get() {
    return UTCToLocal(props.modelValue);
  },
  set(value) {
    emit("update:modelValue", new Date(value));
  },
});

const computeMin = computed((): string | undefined => {
  if (!props.min) {
    return undefined;
  }
  return UTCToLocal(props.min);
});
</script>
