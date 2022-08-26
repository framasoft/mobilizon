<template>
  <div class="container mx-auto">
    <h1 class="">{{ t("Settings") }}</h1>
    <div class="flex flex-wrap gap-2">
      <aside class="sm:max-w-xs flex-1 min-w-[320px]">
        <ul>
          <SettingMenuSection
            :title="t('Settings')"
            :to="{ name: RouteName.GROUP_SETTINGS }"
          >
            <SettingMenuItem
              :title="t('Public')"
              :to="{ name: RouteName.GROUP_PUBLIC_SETTINGS }"
            />
            <SettingMenuItem
              :title="t('Members')"
              :to="{ name: RouteName.GROUP_MEMBERS_SETTINGS }"
            />
            <SettingMenuItem
              :title="t('Followers')"
              :to="{ name: RouteName.GROUP_FOLLOWERS_SETTINGS }"
            />
          </SettingMenuSection>
        </ul>
      </aside>
      <div class="flex-1">
        <router-view />
      </div>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { useHead } from "@vueuse/head";
import RouteName from "@/router/name";
import SettingMenuSection from "@/components/Settings/SettingMenuSection.vue";
import SettingMenuItem from "@/components/Settings/SettingMenuItem.vue";

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Group settings")),
});
</script>
