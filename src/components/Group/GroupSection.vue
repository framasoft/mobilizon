<template>
  <section class="flex flex-col mb-3 border-2 border-yellow-1">
    <div class="flex items-stretch py-3 px-1 bg-yellow-1 text-violet-title">
      <div class="flex flex-1 gap-1">
        <o-icon :icon="icon" custom-size="36" />
        <h2 class="text-2xl font-medium mt-0">{{ title }}</h2>
      </div>
      <router-link class="self-center" :to="route">{{
        t("View all")
      }}</router-link>
    </div>
    <div class="flex-1">
      <slot></slot>
    </div>
    <div class="flex justify-end p-2">
      <slot name="create"></slot>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { useI18n } from "vue-i18n";

withDefaults(
  defineProps<{
    title: string;
    icon: string;
    route: { name: string; params: { preferredUsername: string } };
  }>(),
  {}
);
const { t } = useI18n({ useScope: "global" });
</script>
