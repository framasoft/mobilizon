<template>
  <div class="container mx-auto px-2">
    <h1>{{ t("Terms") }}</h1>
    <o-loading v-model="termsLoading" />
    <div
      class="prose dark:prose-invert"
      v-if="config"
      v-html="config.terms.bodyHtml"
    />
  </div>
</template>

<script lang="ts" setup>
import { TERMS } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { InstanceTermsType } from "@/types/enums";
import { useQuery } from "@vue/apollo-composable";
import { useHead } from "@vueuse/head";
import { computed, watch } from "vue";
import { useI18n } from "vue-i18n";

const { t, locale } = useI18n({ useScope: "global" });

const { result: termsResult, loading: termsLoading } = useQuery<{
  config: IConfig;
}>(
  TERMS,
  () => ({
    locale: locale,
  }),
  () => ({
    enabled: locale !== undefined,
  })
);

const config = computed(() => termsResult.value?.config);

watch(config, () => {
  if (config.value?.terms?.type) {
    redirectToUrl();
  }
});

const redirectToUrl = (): void => {
  if (config.value?.terms?.type === InstanceTermsType.URL) {
    window.location.replace(config.value?.terms?.url);
  }
};

useHead({
  title: computed(() => t("Terms")),
});
</script>
