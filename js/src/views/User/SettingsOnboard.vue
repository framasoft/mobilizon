<template>
  <div class="section container">
    <h1 class="title">{{ $t("Let's define a few settings") }}</h1>
    <settings-onboarding />
    <notifications-onboarding />
    <section class="has-text-centered section">
      <b-button @click="refresh()" type="is-success" size="is-big">
        {{ $t("All good, let's continue!") }}
      </b-button>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { SET_USER_SETTINGS } from "../../graphql/user";
import { TIMEZONES } from "../../graphql/config";
import { IConfig } from "../../types/config.model";

@Component({
  components: {
    NotificationsOnboarding: () => import("../../components/Settings/NotificationsOnboarding.vue"),
    SettingsOnboarding: () => import("../../components/Settings/SettingsOnboarding.vue"),
  },
  apollo: {
    config: TIMEZONES,
  },
})
export default class SettingsOnboard extends Vue {
  config!: IConfig;

  @Watch("config")
  async timezoneLoaded() {
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    if (this.config && this.config.timezones.includes(timezone)) {
      await this.$apollo.mutate<{ setUserSettings: string }>({
        mutation: SET_USER_SETTINGS,
        variables: {
          timezone,
        },
      });
    }
  }

  refresh() {
    location.reload();
  }
}
</script>
