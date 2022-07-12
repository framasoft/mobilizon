<template>
  <label :for="labelFor" class="block mb-2">
    <span class="font-bold mb-2 block">
      {{ label }}
    </span>
    <slot :type="type" />
    <template v-if="Array.isArray(message) && message.length > 0">
      <p v-for="msg in message" :key="msg" :class="classNames">
        {{ msg }}
      </p>
    </template>
    <p v-else-if="typeof message === 'string'" :class="classNames">
      {{ message }}
    </p>
  </label>
</template>
<script lang="ts" setup>
import { computed } from "vue";

const props = defineProps<{
  label: string;
  type?: string;
  message?: string | string[];
  labelFor?: string;
}>();

const classNames = computed(() => {
  switch (props.type) {
    case "is-danger":
      return "text-red-600";
  }
});
</script>
