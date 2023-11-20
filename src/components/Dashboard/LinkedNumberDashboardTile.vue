<template>
  <router-link
    v-if="to?.name"
    :to="to"
    class="bg-white dark:bg-black mb-4 shadow-md rounded p-4"
  >
    <NumberDashboardTile :number="number" :subtitle="subtitle" :style="false">
      <template #subtitle>
        <slot name="subtitle" />
      </template>
    </NumberDashboardTile>
  </router-link>
</template>
<script lang="ts" setup>
import NumberDashboardTile from "./NumberDashboardTile.vue";
defineProps<{
  number?: number;
  subtitle?: string;
  to?: {
    name: string;
    params?: Record<string, any>;
    query?: Record<string, any>;
  };
}>();
</script>
