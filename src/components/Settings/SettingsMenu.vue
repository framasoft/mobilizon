<template>
  <aside class="mb-6">
    <ul>
      <SettingMenuSection
        :title="t('Account')"
        :to="{ name: RouteName.ACCOUNT_SETTINGS }"
      >
        <SettingMenuItem
          :title="t('General')"
          :to="{ name: RouteName.ACCOUNT_SETTINGS_GENERAL }"
        />
        <SettingMenuItem
          :title="t('Preferences')"
          :to="{ name: RouteName.PREFERENCES }"
        />
        <SettingMenuItem
          :title="t('Notifications')"
          :to="{ name: RouteName.NOTIFICATIONS }"
        />
        <SettingMenuItem
          :title="t('Apps')"
          :to="{ name: RouteName.AUTHORIZED_APPS }"
        />
      </SettingMenuSection>
      <SettingMenuSection
        :title="t('Profiles')"
        :to="{ name: RouteName.IDENTITIES }"
      >
        <SettingMenuItem
          v-for="profile in identities"
          :key="profile.preferredUsername"
          :title="profile.preferredUsername"
          :to="{
            name: RouteName.UPDATE_IDENTITY,
            params: { identityName: profile.preferredUsername },
          }"
        />
        <SettingMenuItem
          :title="t('New profile')"
          :to="{ name: RouteName.CREATE_IDENTITY }"
        />
      </SettingMenuSection>
      <SettingMenuSection
        v-if="
          currentUser?.role &&
          [ICurrentUserRole.MODERATOR, ICurrentUserRole.ADMINISTRATOR].includes(
            currentUser?.role
          )
        "
        :title="t('Moderation')"
        :to="{ name: RouteName.MODERATION }"
      >
        <SettingMenuItem
          :title="t('Reports')"
          :to="{ name: RouteName.REPORTS }"
        />
        <SettingMenuItem
          :title="t('Moderation log')"
          :to="{ name: RouteName.REPORT_LOGS }"
        />
        <SettingMenuItem :title="t('Users')" :to="{ name: RouteName.USERS }" />
        <SettingMenuItem
          :title="t('Profiles')"
          :to="{ name: RouteName.PROFILES }"
        />
        <SettingMenuItem
          :title="t('Groups')"
          :to="{ name: RouteName.ADMIN_GROUPS }"
        />
      </SettingMenuSection>
      <SettingMenuSection
        v-if="currentUser?.role == ICurrentUserRole.ADMINISTRATOR"
        :title="t('Admin')"
        :to="{ name: RouteName.ADMIN }"
      >
        <SettingMenuItem
          :title="t('Dashboard')"
          :to="{ name: RouteName.ADMIN_DASHBOARD }"
        />
        <SettingMenuItem
          :title="t('Instance settings')"
          :to="{ name: RouteName.ADMIN_SETTINGS }"
        />
        <SettingMenuItem
          :title="t('Federation')"
          :to="{ name: RouteName.INSTANCES }"
        />
      </SettingMenuSection>
    </ul>
  </aside>
</template>
<script lang="ts" setup>
import { ICurrentUserRole } from "@/types/enums";
import SettingMenuSection from "./SettingMenuSection.vue";
import SettingMenuItem from "./SettingMenuItem.vue";

import RouteName from "../../router/name";
import { useCurrentUserClient } from "@/composition/apollo/user";
import { useCurrentUserIdentities } from "@/composition/apollo/actor";
import { useI18n } from "vue-i18n";

const { currentUser } = useCurrentUserClient();
const { identities } = useCurrentUserIdentities();

const { t } = useI18n({ useScope: "global" });
</script>
<style lang="scss" scoped>
:deep(a) {
  text-decoration: none;
}
</style>
