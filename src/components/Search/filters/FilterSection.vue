<template>
  <div class="border-b border-gray-200 dark:border-gray-500 py-6">
    <h2 class="-my-3 flow-root">
      <!-- Expand/collapse section button -->
      <button
        type="button"
        class="py-3 w-full flex items-center justify-between text-gray-400 hover:text-gray-500 dark:text-slate-100 hover:dark:text-slate-200"
        aria-controls="filter-section-mobile-0"
        :aria-expanded="opened"
        @click="$emit('update:opened', !opened)"
      >
        <div class="flex flex-wrap gap-1 flex-col items-start">
          <span class="font-medium text-gray-900 dark:text-slate-100 text-left">
            {{ title }}
          </span>
          <slot name="preview" />
        </div>
        <span class="ml-6 flex items-center">
          <svg
            v-show="!opened"
            class="h-5 w-5"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
          >
            <path
              fill-rule="evenodd"
              d="M10 5a1 1 0 011 1v3h3a1 1 0 110 2h-3v3a1 1 0 11-2 0v-3H6a1 1 0 110-2h3V6a1 1 0 011-1z"
              clip-rule="evenodd"
            />
          </svg>
          <svg
            v-show="opened"
            class="h-5 w-5"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
          >
            <path
              fill-rule="evenodd"
              d="M5 10a1 1 0 011-1h8a1 1 0 110 2H6a1 1 0 01-1-1z"
              clip-rule="evenodd"
            />
          </svg>
        </span>
      </button>
    </h2>
    <!-- Filter section, show/hide based on section state. -->
    <transition>
      <div v-show="opened" class="pt-2">
        <slot name="options" />
      </div>
    </transition>
  </div>
</template>
<script setup lang="ts">
defineProps({
  title: {
    required: true,
    type: String,
  },
  opened: {
    required: true,
    type: Boolean,
  },
});
defineEmits(["update:opened"]);
</script>
