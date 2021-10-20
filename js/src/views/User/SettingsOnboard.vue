<template>
  <div class="section container">
    <h1 class="title">{{ $t("Let's define a few settings") }}</h1>
    <b-steps v-model="stepIndex" :has-navigation="false">
      <b-step-item step="1" :label="$t('Settings')">
        <settings-onboarding />
      </b-step-item>
      <b-step-item step="2" :label="$t('Participation notifications')">
        <notifications-onboarding />
      </b-step-item>
      <b-step-item step="3" :label="$t('Profiles and federation')">
        <profile-onboarding />
      </b-step-item>
    </b-steps>
    <section class="has-text-centered section buttons">
      <b-button
        outlined
        :disabled="stepIndex < 1"
        tag="router-link"
        :to="{
          name: RouteName.WELCOME_SCREEN,
          params: { step: stepIndex },
        }"
      >
        {{ $t("Previous") }}
      </b-button>
      <b-button
        outlined
        type="is-success"
        v-if="stepIndex < 2"
        tag="router-link"
        :to="{
          name: RouteName.WELCOME_SCREEN,
          params: { step: stepIndex + 2 },
        }"
      >
        {{ $t("Next") }}
      </b-button>
      <b-button
        v-if="stepIndex >= 2"
        type="is-success"
        size="is-big"
        tag="router-link"
        :to="{ name: RouteName.HOME }"
      >
        {{ $t("All good, let's continue!") }}
      </b-button>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { TIMEZONES } from "../../graphql/config";
import RouteName from "../../router/name";
import { IConfig } from "../../types/config.model";

@Component({
  components: {
    NotificationsOnboarding: () =>
      import("../../components/Settings/NotificationsOnboarding.vue"),
    SettingsOnboarding: () =>
      import("../../components/Settings/SettingsOnboarding.vue"),
    ProfileOnboarding: () =>
      import("../../components/Account/ProfileOnboarding.vue"),
  },
  apollo: {
    config: TIMEZONES,
  },
  metaInfo() {
    return {
      title: this.$t("First steps") as string,
    };
  },
})
export default class SettingsOnboard extends Vue {
  @Prop({ required: false, default: 1, type: Number }) step!: number;

  config!: IConfig;

  RouteName = RouteName;

  get stepIndex(): number {
    return this.step - 1;
  }
}
</script>
<style scoped lang="scss">
.section.container {
  .has-text-centered.section.buttons {
    justify-content: center;
  }
}
</style>
