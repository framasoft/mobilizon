<template>
  <section class="container mx-auto">
    <span v-if="code === ErrorCode.REGISTRATION_CLOSED">
      {{ t("Registration is currently closed.") }}
    </span>

    <span v-else>
      {{ t("Unknown error.") }}
    </span>
  </section>
</template>

<script lang="ts" setup>
import { ErrorCode } from "@/types/enums";
import { useHead } from "@vueuse/head";
import { useI18n } from "vue-i18n";
import { useRouteQuery } from "vue-use-route-query";
import { computed } from "vue";

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Error")),
});

const code = useRouteQuery("code", null);
</script>
