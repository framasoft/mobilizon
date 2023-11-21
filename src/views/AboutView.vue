<template>
  <div>
    <section class="container mx-auto">
      <div class="flex flex-wrap gap-4">
        <aside class="w-64 mt-6">
          <div
            class="overflow-y-auto py-4 px-3 bg-gray-50 rounded dark:bg-gray-800"
          >
            <p>
              <router-link
                class="flex items-center p-2 text-base font-normal text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700"
                :to="{ name: RouteName.ABOUT_INSTANCE }"
                >{{ t("About this instance") }}</router-link
              >
            </p>
            <p class="menu-label has-text-grey-dark">
              {{ t("Legal") }}
            </p>
            <ul>
              <li>
                <router-link
                  class="flex items-center p-2 text-base font-normal text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700"
                  :to="{ name: RouteName.TERMS }"
                  >{{ t("Terms of service") }}</router-link
                >
              </li>
              <li>
                <router-link
                  class="flex items-center p-2 text-base font-normal text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700"
                  :to="{ name: RouteName.PRIVACY }"
                  >{{ t("Privacy policy") }}</router-link
                >
              </li>
              <li>
                <router-link
                  class="flex items-center p-2 text-base font-normal text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700"
                  :to="{ name: RouteName.RULES }"
                  >{{ t("Instance rules") }}</router-link
                >
              </li>
              <li>
                <router-link
                  class="flex items-center p-2 text-base font-normal text-gray-900 rounded-lg dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700"
                  :to="{ name: RouteName.GLOSSARY }"
                  >{{ t("Glossary") }}</router-link
                >
              </li>
            </ul>
          </div>
        </aside>
        <div class="container mx-auto flex-1 bg-white dark:bg-gray-700">
          <router-view />
        </div>
      </div>
    </section>
    <div class="bg-secondary dark:bg-gray-700 p-6">
      <div class="container mx-auto">
        <h1 class="text-4xl font-bold text-black/70">
          {{ t("Powered by Mobilizon") }}
        </h1>
        <p>
          {{
            t(
              "A user-friendly, emancipatory and ethical tool for gathering, organising, and mobilising."
            )
          }}
        </p>
        <o-button
          tag="a"
          icon-left="open-in-new"
          class="text-2xl bg-primary text-white leading-6"
          href="https://joinmobilizon.org"
          >{{ t("Learn more") }}</o-button
        >
      </div>
    </div>
    <div v-if="!currentUser || !currentUser.id" class="bg-purple-2 pb-3">
      <div class="container mx-auto text-center py-10 px-6">
        <div class="flex flex-wrap">
          <div class="flex-1" v-if="config && config.registrationsOpen">
            <h2 class="text-4xl text-violet-1 font-bold">
              {{ t("Register on this instance") }}
            </h2>
            <o-button
              tag="router-link"
              class="bg-secondary text-lg text-black"
              :to="{ name: RouteName.REGISTER }"
              >{{ t("Create an account") }}</o-button
            >
          </div>
          <div class="flex-1">
            <h2 class="text-4xl text-violet-1 font-bold">
              {{ t("Find another instance") }}
            </h2>
            <o-button
              tag="a"
              class="bg-secondary text-lg text-black"
              href="https://mobilizon.org"
              >{{ t("Pick an instance") }}</o-button
            >
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ABOUT } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import RouteName from "../router/name";
import { useQuery } from "@vue/apollo-composable";
import { computed } from "vue";
import { useCurrentUserClient } from "@/composition/apollo/user";
import { useI18n } from "vue-i18n";
import { useHead } from "@unhead/vue";

const { currentUser } = useCurrentUserClient();

const { result: configResult } = useQuery<{ config: IConfig }>(ABOUT);

const config = computed(() => configResult.value?.config);

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() =>
    t("About {instance}", { instance: config.value?.name })
  ),
});

// metaInfo() {
//   return {
//     title: this.t("About {instance}", {
//       // eslint-disable-next-line @typescript-eslint/ban-ts-comment
//       // @ts-ignore
//       instance: this?.config?.name,
//     }) as string,
//   };
// },
</script>
