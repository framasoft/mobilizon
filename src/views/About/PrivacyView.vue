<template>
  <div class="container mx-auto px-2">
    <h1>{{ t("Privacy Policy") }}</h1>
    <div
      class="prose dark:prose-invert"
      v-if="config?.privacy"
      v-html="config.privacy.bodyHtml"
    />
  </div>
</template>

<script lang="ts" setup>
import { PRIVACY } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { InstancePrivacyType } from "@/types/enums";
import { useQuery } from "@vue/apollo-composable";
import { useHead } from "@vueuse/head";
import { computed, watch } from "vue";
import { useI18n } from "vue-i18n";

const { locale } = useI18n({ useScope: "global" });

const { result: configResult } = useQuery<{ config: IConfig }>(
  PRIVACY,
  () => ({
    locale: locale,
  }),
  () => ({
    enabled: locale !== undefined,
  })
);

const config = computed(() => configResult.value?.config);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: t("Privacy Policy"),
});

watch(config, () => {
  if (config.value?.privacy?.type === InstancePrivacyType.URL) {
    window.location.replace(config.value?.privacy?.url);
  }
});
</script>
