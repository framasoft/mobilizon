<template>
  <div
    :class="`bg-white dark:bg-slate-800 shadow rounded-md ${
      isRowMode ? 'max-w-4xl' : 'max-w-sm'
    } w-full mx-auto`"
  >
    <div
      :class="`animate-pulse flex flex-col items-center ${
        isRowMode ? 'md:flex-row' : 'md:flex-col'
      }`"
    >
      <div class="object-cover h-56 w-full md:max-w-[20rem] bg-slate-700" />

      <div
        class="flex-1 space-3-4 flex self-start flex-col justify-between p-2 md:p-4 w-full"
      >
        <span class="h-2 bg-slate-700"></span>
        <span class="mb-2 h-4 bg-slate-700"></span>

        <div class="flex space-x-4 flex-row">
          <div class="rounded-full bg-slate-700 h-10 w-10"></div>
          <div class="flex flex-col flex-1 space-y-2">
            <div class="h-3 bg-slate-700"></div>
            <div class="h-2 bg-slate-700"></div>
          </div>
        </div>
        <div class="h-3 bg-slate-700 mt-3 w-60" v-if="!minimal"></div>
        <div class="flex" v-if="!minimal">
          <div
            class="h-3 bg-slate-700 mt-2 w-20 mr-2 rounded"
            v-for="i in 3"
            :key="i"
          ></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { computed } from "vue";
const props = withDefaults(
  defineProps<{
    viewMode?: string;
    minimal?: boolean;
  }>(),
  { viewMode: "row", minimal: true }
);

const isRowMode = computed<boolean>(() => props.viewMode == "row");
</script>
