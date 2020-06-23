<template>
  <div v-if="loggedUser">
    <section>
      <div class="setting-title">
        <h2>{{ $t("Settings") }}</h2>
      </div>
      <h3>{{ $t("Timezone") }}</h3>
      <p>
        {{
          $t(
            "We use your timezone to make sure you get notifications for an event at the correct time."
          )
        }}
        {{
          $t("Your timezone was detected as {timezone}.", {
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
          })
        }}
      </p>
      <div class="has-text-centered">
        <router-link :to="{ name: RouteName.PREFERENCES }" class="button is-primary is-outlined">{{
          $t("Manage my settings")
        }}</router-link>
      </div>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { USER_SETTINGS, SET_USER_SETTINGS } from "../../graphql/user";
import {
  ICurrentUser,
  INotificationPendingParticipationEnum,
} from "../../types/current-user.model";
import RouteName from "../../router/name";

@Component({
  apollo: {
    loggedUser: USER_SETTINGS,
  },
})
export default class SettingsOnboarding extends Vue {
  loggedUser!: ICurrentUser;

  notificationOnDay = true;

  RouteName = RouteName;

  async updateSetting(variables: object) {
    await this.$apollo.mutate<{ setUserSettings: string }>({
      mutation: SET_USER_SETTINGS,
      variables,
    });
  }
}
</script>
<style lang="scss" scoped>
h3 {
  font-weight: bold;
}
</style>
