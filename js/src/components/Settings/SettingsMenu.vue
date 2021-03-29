<template>
  <aside>
    <ul>
      <SettingMenuSection
        :title="$t('Account')"
        :to="{ name: RouteName.ACCOUNT_SETTINGS }"
      >
        <SettingMenuItem
          :title="this.$t('General')"
          :to="{ name: RouteName.ACCOUNT_SETTINGS_GENERAL }"
        />
        <SettingMenuItem
          :title="$t('Preferences')"
          :to="{ name: RouteName.PREFERENCES }"
        />
        <SettingMenuItem
          :title="this.$t('Notifications')"
          :to="{ name: RouteName.NOTIFICATIONS }"
        />
      </SettingMenuSection>
      <SettingMenuSection
        :title="$t('Profiles')"
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
          :title="$t('New profile')"
          :to="{ name: RouteName.CREATE_IDENTITY }"
        />
      </SettingMenuSection>
      <SettingMenuSection
        v-if="
          [ICurrentUserRole.MODERATOR, ICurrentUserRole.ADMINISTRATOR].includes(
            this.currentUser.role
          )
        "
        :title="$t('Moderation')"
        :to="{ name: RouteName.MODERATION }"
      >
        <SettingMenuItem
          :title="$t('Reports')"
          :to="{ name: RouteName.REPORTS }"
        />
        <SettingMenuItem
          :title="$t('Moderation log')"
          :to="{ name: RouteName.REPORT_LOGS }"
        />
        <SettingMenuItem :title="$t('Users')" :to="{ name: RouteName.USERS }" />
        <SettingMenuItem
          :title="$t('Profiles')"
          :to="{ name: RouteName.PROFILES }"
        />
        <SettingMenuItem
          :title="$t('Groups')"
          :to="{ name: RouteName.ADMIN_GROUPS }"
        />
      </SettingMenuSection>
      <SettingMenuSection
        v-if="this.currentUser.role == ICurrentUserRole.ADMINISTRATOR"
        :title="$t('Admin')"
        :to="{ name: RouteName.ADMIN }"
      >
        <SettingMenuItem
          :title="$t('Dashboard')"
          :to="{ name: RouteName.ADMIN_DASHBOARD }"
        />
        <SettingMenuItem
          :title="$t('Instance settings')"
          :to="{ name: RouteName.ADMIN_SETTINGS }"
        />
        <SettingMenuItem
          :title="$t('Federation')"
          :to="{ name: RouteName.RELAYS }"
        />
      </SettingMenuSection>
    </ul>
  </aside>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { ICurrentUserRole } from "@/types/enums";
import SettingMenuSection from "./SettingMenuSection.vue";
import SettingMenuItem from "./SettingMenuItem.vue";
import { IDENTITIES } from "../../graphql/actor";
import { IPerson, Person } from "../../types/actor";
import { CURRENT_USER_CLIENT } from "../../graphql/user";
import { ICurrentUser } from "../../types/current-user.model";

import RouteName from "../../router/name";

@Component({
  components: { SettingMenuSection, SettingMenuItem },
  apollo: {
    identities: {
      query: IDENTITIES,
      update: (data) =>
        data.identities.map((identity: IPerson) => new Person(identity)),
    },
    currentUser: CURRENT_USER_CLIENT,
  },
})
export default class SettingsMenu extends Vue {
  profiles = [];

  currentUser!: ICurrentUser;

  identities!: IPerson[];

  ICurrentUserRole = ICurrentUserRole;

  RouteName = RouteName;
}
</script>
<style lang="scss" scoped>
::v-deep a {
  text-decoration: none;
}
</style>
