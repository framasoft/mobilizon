<template>
  <div class="container mx-auto py-4 px-2">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
      <div>
        <h3 class="dark:text-white text-3xl font-bold">
          {{ t("A practical tool") }}
        </h3>
        <i18n-t
          tag="p"
          class="dark:text-white"
          keypath="Mobilizon is a tool that helps you {find_create_organize_events}."
        >
          <template #find_create_organize_events>
            <b>{{ t("find, create and organise events") }}</b>
          </template>
        </i18n-t>
      </div>
      <div>
        <h3 class="dark:text-white text-3xl font-bold">
          {{ t("An ethical alternative") }}
        </h3>
        <i18n-t
          tag="p"
          class="dark:text-white"
          keypath="Ethical alternative to Facebook events, groups and pages, Mobilizon is a {tool_designed_to_serve_you}. Period."
        >
          <template #tool_designed_to_serve_you>
            <b>{{ t("tool designed to serve you") }}</b>
          </template>
        </i18n-t>
      </div>
      <div>
        <h3 class="dark:text-white text-3xl font-bold">
          {{ t("A federated software") }}
        </h3>
        <i18n-t
          tag="p"
          class="dark:text-white"
          keypath="Mobilizon is not a giant platform, but a {multitude_of_interconnected_mobilizon_websites}."
        >
          <template #multitude_of_interconnected_mobilizon_websites>
            <b>{{ t("multitude of interconnected Mobilizon websites") }}</b>
          </template>
        </i18n-t>
      </div>
    </div>
    <div class="mt-4 text-center">
      <o-button
        variant="primary"
        size="large"
        tag="a"
        href="https://joinmobilizon.org"
        >{{ t("Learn more about Mobilizon") }}</o-button
      >
    </div>
  </div>
</template>
<script lang="ts" setup>
import { useI18n } from "vue-i18n";

const { t } = useI18n({ useScope: "global" });
</script>
