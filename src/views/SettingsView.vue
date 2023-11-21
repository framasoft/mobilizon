<template>
  <div class="container mx-auto">
    <h1 class="text-violet-3 dark:text-white">{{ t("Settings") }}</h1>
    <div class="flex flex-wrap gap-4">
      <SettingsMenu class="max-w-xs w-full" />
      <div class="flex-1">
        <router-view />
      </div>
    </div>
  </div>
</template>
<script lang="ts" setup>
import SettingsMenu from "../components/Settings/SettingsMenu.vue";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { useHead } from "@unhead/vue";

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Settings")),
});
</script>
