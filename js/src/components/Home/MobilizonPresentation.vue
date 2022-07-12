<template>
  <div class="container mx-auto py-4 px-2">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
      <div>
        <h3 class="dark:text-white text-3xl font-bold">
          {{ t("A practical tool") }}
        </h3>
        <p
          class="dark:text-white"
          v-html="
            t(
              'Mobilizon is a tool that helps you <b>find, create and organise events</b>.'
            )
          "
        />
      </div>
      <div>
        <h3 class="dark:text-white text-3xl font-bold">
          {{ t("An ethical alternative") }}
        </h3>
        <p
          class="dark:text-white"
          v-html="
            t(
              'Ethical alternative to Facebook events, groups and pages, Mobilizon is a <b>tool designed to serve you</b>. Period.'
            )
          "
        />
      </div>
      <div>
        <h3 class="dark:text-white text-3xl font-bold">
          {{ t("A federated software") }}
        </h3>
        <p
          class="dark:text-white"
          v-html="
            t(
              'Mobilizon is not a giant platform, but a <b>multitude of interconnected Mobilizon websites</b>.'
            )
          "
        />
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
