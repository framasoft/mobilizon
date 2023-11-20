<template>
  <nav class="flex mb-3" :aria-label="t('Breadcrumbs')">
    <ol class="inline-flex items-center space-x-1 md:space-x-3 flex-wrap">
      <li
        class="inline-flex items-center"
        v-for="(element, index) in links"
        :key="index"
        :aria-current="index > 0 ? 'page' : undefined"
      >
        <router-link
          v-if="index === 0"
          :to="element"
          class="inline-flex items-center text-gray-800 hover:text-gray-900 dark:text-gray-200 dark:hover:text-gray-100"
        >
          {{ element.text }}
        </router-link>
        <div class="flex items-center" v-else-if="index === links.length - 1">
          <svg
            class="w-6 h-6 text-gray-400 dark:text-gray-100 rtl:rotate-180"
            fill="currentColor"
            viewBox="0 0 20 20"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              fill-rule="evenodd"
              d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
              clip-rule="evenodd"
            ></path>
          </svg>
          <span
            class="ltr:ml-1 rtl:mr-1 font-medium text-gray-600 dark:text-gray-300 md:ltr:ml-2 md:rtl:mr-2 line-clamp-1"
            >{{ element.text }}</span
          >
        </div>
        <div class="flex items-center" v-else>
          <svg
            class="w-6 h-6 text-gray-400 dark:text-gray-100 rtl:rotate-180"
            fill="currentColor"
            viewBox="0 0 20 20"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              fill-rule="evenodd"
              d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
              clip-rule="evenodd"
            ></path>
          </svg>
          <router-link
            :to="element"
            class="ltr:ml-1 rtl:mr-1 font-medium text-gray-800 hover:text-gray-900 dark:text-gray-200 dark:hover:text-gray-100 md:ltr:ml-2 md:rtl:mr-2 line-clamp-1"
            >{{ element.text }}</router-link
          >
        </div>
      </li>
      <slot></slot>
    </ol>
  </nav>
</template>
<script lang="ts" setup>
import { useI18n } from "vue-i18n";
import { RouteLocationRaw } from "vue-router";

type LinkElement = RouteLocationRaw & { text: string };

defineProps<{
  links: LinkElement[];
}>();

const { t } = useI18n({ useScope: "global" });
</script>
