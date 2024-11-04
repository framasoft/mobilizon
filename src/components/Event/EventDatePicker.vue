<template>
  <input
    type="datetime-local"
    class="rounded invalid:border-red-500"
    v-model="component"
    :min="computeMin"
    @blur="$emit('blur')"
  />
</template>
<script lang="ts" setup>
import { computed } from "vue";

const props = withDefaults(
  defineProps<{
    modelValue: Date | null;
    min?: Date | null | undefined;
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
    if (!props.modelValue) {
      return null;
    }
    return UTCToLocal(props.modelValue);
  },
  set(value) {
    console.log("value" + value);
    if (!value) {
      emit("update:modelValue", null);
      return;
    }
    const date = new Date(value);
    emit("update:modelValue", date);
  },
});

const computeMin = computed((): string | undefined => {
  if (!props.min) {
    return undefined;
  }
  return UTCToLocal(props.min);
});
</script>
