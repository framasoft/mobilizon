<template>
  <Switch
    v-model="modelValue"
    :class="disabled ? 'bg-teal-700' : 'bg-teal-900'"
    class="relative inline-flex h-6 w-11 items-center rounded-full"
  >
    <span class="sr-only"><slot /></span>
    <span
      :class="disabled ? 'translate-x-1' : 'translate-x-6'"
      class="inline-block h-4 w-4 transform rounded-full bg-white"
    />
  </Switch>
</template>
<script lang="ts" setup>
import { Switch } from "@headlessui/vue";
withDefaults(
  defineProps<{
    modelValue: boolean;
    disabled?: boolean;
    required?: boolean;
  }>(),
  {
    disabled: false,
    required: false,
  }
);
</script>
