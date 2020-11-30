<template>
  <div class="section container">
    <h1 class="title">{{ $t("Let's define a few settings") }}</h1>
    <b-steps v-model="realActualStepIndex" :has-navigation="false">
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
        :disabled="realActualStepIndex < 1"
        tag="router-link"
        :to="{
          name: RouteName.WELCOME_SCREEN,
          params: { step: actualStepIndex - 1 },
        }"
      >
        {{ $t("Previous") }}
      </b-button>
      <b-button
        outlined
        type="is-success"
        v-if="realActualStepIndex < 2"
        tag="router-link"
        :to="{
          name: RouteName.WELCOME_SCREEN,
          params: { step: actualStepIndex + 1 },
        }"
      >
        {{ $t("Next") }}
      </b-button>
      <b-button
        v-if="realActualStepIndex >= 2"
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
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
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
})
export default class SettingsOnboard extends Vue {
  @Prop({ required: false, default: 1, type: Number }) step!: number;

  config!: IConfig;

  RouteName = RouteName;

  actualStepIndex = this.step;

  @Watch("step")
  updateActualStep(): void {
    if (this.step) {
      this.actualStepIndex = this.step;
    }
  }

  get realActualStepIndex(): number {
    return this.actualStepIndex - 1;
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
