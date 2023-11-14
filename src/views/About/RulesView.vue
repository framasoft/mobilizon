<template>
  <div class="container mx-auto px-2" v-if="config">
    <h1>{{ t("Rules") }}</h1>
    <div
      class="prose dark:prose-invert"
      v-html="config.rules"
      v-if="config.rules"
    />
    <p v-else>{{ t("No rules defined yet.") }}</p>
  </div>
</template>

<script lang="ts" setup>
import { RULES } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { useQuery } from "@vue/apollo-composable";
import { useHead } from "@vueuse/head";
import { computed } from "vue";
import { useI18n } from "vue-i18n";

const { result: configResult } = useQuery<{ config: IConfig }>(RULES);

const config = computed(() => configResult.value?.config);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: t("Rules"),
});
</script>
