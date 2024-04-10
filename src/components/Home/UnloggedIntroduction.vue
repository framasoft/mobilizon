<template>
  <section class="container mx-auto px-2 my-3">
    <h1 class="dark:text-white font-bold">
      {{ config.slogan ?? t("Gather ⋅ Organize ⋅ Mobilize") }}
    </h1>

    <p class="dark:text-white mb-2">{{ config.description }}</p>
  </section>
</template>
<script lang="ts" setup>
import { IConfig } from "@/types/config.model";
import { useI18n } from "vue-i18n";

defineProps<{
  config: Pick<
    IConfig,
    "name" | "description" | "slogan" | "registrationsOpen"
  >;
}>();

const { t } = useI18n({ useScope: "global" });
</script>
