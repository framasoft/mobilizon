<template>
  <section class="container mx-auto px-2 my-3">
    <h1 class="dark:text-white font-bold">
      {{ config.slogan ?? t("Gather ⋅ Organize ⋅ Mobilize") }}
    </h1>
    <i18n-t
      keypath="Join {instance}, a Mobilizon instance"
      tag="p"
      class="dark:text-white"
    >
      <template #instance>
        <b>{{ config.name }}</b>
      </template>
    </i18n-t>
    <p class="dark:text-white mb-2">{{ config.description }}</p>
    <!-- We don't invite to find other instances yet -->
    <!-- <p v-if="!config.registrationsOpen">
              {{ t("This instance isn't opened to registrations, but you can register on other instances.") }}
          </p>-->
    <div class="flex flex-wrap gap-2 items-center">
      <o-button
        variant="primary"
        tag="router-link"
        :to="{ name: RouteName.REGISTER }"
        v-if="config.registrationsOpen"
        >{{ t("Create an account") }}</o-button
      >
      <!-- We don't invite to find other instances yet -->
      <!-- <o-button v-else variant="link" tag="a" href="https://joinmastodon.org">{{ t('Find an instance') }}</o-button> -->
      <router-link
        :to="{ name: RouteName.ABOUT }"
        class="py-2.5 px-5 text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-100 hover:text-violet-title focus:z-10 focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700"
      >
        {{ t("Learn more about {instance}", { instance: config.name }) }}
      </router-link>
    </div>
  </section>
</template>
<script lang="ts" setup>
import { IConfig } from "@/types/config.model";
import RouteName from "@/router/name";
import { useI18n } from "vue-i18n";

defineProps<{
  config: Pick<
    IConfig,
    "name" | "description" | "slogan" | "registrationsOpen"
  >;
}>();

const { t } = useI18n({ useScope: "global" });
</script>
