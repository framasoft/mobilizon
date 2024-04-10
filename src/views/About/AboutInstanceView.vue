<template>
  <div v-if="config">
    <section class="p-6 bg-primary text-white">
      <h1 dir="auto">{{ config.name }}</h1>
      <p dir="auto">{{ config.description }}</p>
    </section>
    <section
      class="px-2 flex flex-wrap gap-2 contact-statistics"
      v-if="statistics"
    >
      <div class="statistics flex-1 min-w-[20rem]">
        <i18n-t tag="p" keypath="Home to {number} users">
          <template #number>
            <strong>{{ statistics.numberOfUsers }}</strong>
          </template>
        </i18n-t>
        <i18n-t tag="p" keypath="and {number} groups">
          <template #number>
            <strong>{{ statistics.numberOfLocalGroups }}</strong>
          </template>
        </i18n-t>
        <i18n-t tag="p" keypath="Who published {number} events">
          <template #number>
            <strong>{{ statistics.numberOfLocalEvents }}</strong>
          </template>
        </i18n-t>
        <i18n-t tag="p" keypath="And {number} comments">
          <template #number>
            <strong>{{ statistics.numberOfLocalComments }}</strong>
          </template>
        </i18n-t>
      </div>
      <div class="">
        <p class="font-bold">{{ t("Contact") }}</p>
        <instance-contact-link
          v-if="config && config.contact"
          :contact="config.contact"
        />
        <p v-else>{{ t("No information") }}</p>
      </div>
    </section>
    <hr role="presentation" v-if="config.longDescription" />
    <section class="long-description content">
      <div v-html="config.longDescription" />
    </section>
    <hr role="presentation" />
    <section class="px-3">
      <h2 class="text-xl">{{ t("Instance configuration") }}</h2>
      <table class="border-collapse table-auto w-full">
        <tr class="bg-white border-b dark:bg-gray-800 dark:border-gray-700">
          <td>{{ t("Instance languages") }}</td>
          <td
            v-if="config.languages.length > 0"
            :title="config.languages.join(', ') ?? ''"
          >
            {{ formattedLanguageList }}
          </td>
          <td v-else>{{ t("No information") }}</td>
        </tr>
        <tr class="bg-white border-b dark:bg-gray-800 dark:border-gray-700">
          <td>{{ t("Mobilizon version") }}</td>
          <td>{{ config.version }}</td>
        </tr>
        <tr class="bg-white border-b dark:bg-gray-800 dark:border-gray-700">
          <td>{{ t("Registrations") }}</td>
          <td v-if="config.registrationsOpen && config.registrationsAllowlist">
            {{ t("Restricted") }}
          </td>
          <td v-if="config.registrationsOpen && !config.registrationsAllowlist">
            {{ t("Open") }}
          </td>
          <td v-else>{{ t("Closed") }}</td>
        </tr>
        <tr class="bg-white border-b dark:bg-gray-800 dark:border-gray-700">
          <td>{{ t("Federation") }}</td>
          <td v-if="config.federating">{{ t("Enabled") }}</td>
          <td v-else>{{ t("Disabled") }}</td>
        </tr>
        <tr class="bg-white border-b dark:bg-gray-800 dark:border-gray-700">
          <td>{{ t("Anonymous participations") }}</td>
          <td v-if="config.anonymous.participation.allowed">
            {{ t("If allowed by organizer") }}
          </td>
          <td v-else>{{ t("Disabled") }}</td>
        </tr>
        <tr class="bg-white border-b dark:bg-gray-800 dark:border-gray-700">
          <td>{{ t("Instance feeds") }}</td>
          <td v-if="config.instanceFeeds.enabled" class="flex gap-2">
            <o-button
              tag="a"
              size="small"
              icon-left="rss"
              href="/feed/instance/atom"
              target="_blank"
              >{{ t("RSS/Atom Feed") }}</o-button
            >

            <o-button
              tag="a"
              size="small"
              icon-left="calendar-sync"
              href="/feed/instance/ics"
              target="_blank"
              >{{ t("ICS/WebCal Feed") }}</o-button
            >
          </td>
          <td v-else>{{ t("Disabled") }}</td>
        </tr>
      </table>
    </section>
  </div>
</template>

<script lang="ts" setup>
import { formatList } from "@/utils/i18n";
import InstanceContactLink from "@/components/About/InstanceContactLink.vue";
import { LANGUAGES_CODES } from "@/graphql/admin";
import { ILanguage } from "@/types/admin.model";
import { ABOUT } from "../../graphql/config";
import { STATISTICS } from "../../graphql/statistics";
import { IConfig } from "../../types/config.model";
import { IStatistics } from "../../types/statistics.model";
import { useQuery } from "@vue/apollo-composable";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { useHead } from "@/utils/head";

const { result: configResult } = useQuery<{ config: IConfig }>(ABOUT);

const config = computed(() => configResult.value?.config);

const { result: statisticsResult } = useQuery<{ statistics: IStatistics }>(
  STATISTICS
);

const statistics = computed(() => statisticsResult.value?.statistics);

const { result: languagesResult } = useQuery<{ languages: ILanguage[] }>(
  LANGUAGES_CODES,
  () => ({
    codes: config.value?.languages,
  }),
  () => ({
    enabled: config.value?.languages !== undefined,
  })
);

const languages = computed(() => languagesResult.value?.languages);

const formattedLanguageList = computed((): string => {
  if (languages.value) {
    const list = languages.value?.map(({ name }) => name) ?? [];
    return formatList(list);
  }
  return "";
});

const { t } = useI18n({ useScope: "global" });

useHead({
  title: t("About {instance}", { instance: config.value?.name }),
});
</script>

<style lang="scss" scoped>
section {
  &:not(:first-child) {
    margin: 2rem auto;
  }

  &.hero {
    h1.title {
      margin: auto;
    }
  }

  &.contact-statistics {
    margin: 2px auto;
    .statistics {
      display: grid;
      grid-template-columns: repeat(auto-fit, 150px);
      gap: 2rem 0;
      p {
        text-align: right;
        padding: 0 15px;

        & > * {
          display: block;
        }

        strong {
          font-weight: 500;
          font-size: 32px;
          line-height: 48px;
        }
      }
    }
  }
  tr.instance-feeds {
    height: 3rem;
    td:first-child {
      vertical-align: middle;
    }
    td:last-child {
      height: 3rem;
    }
  }
}
</style>
