<template>
  <div class="container mx-auto">
    <h1 class="title">{{ $t("Let's define a few settings") }}</h1>
    <o-steps v-model="stepIndex" :has-navigation="false">
      <o-step-item step="1" :label="$t('Settings')">
        <settings-onboarding />
      </o-step-item>
      <o-step-item step="2" :label="$t('Participation notifications')">
        <notifications-onboarding />
      </o-step-item>
      <o-step-item step="3" :label="$t('Profiles and federation')">
        <ProfileOnboarding
          v-if="currentActor && instanceName"
          :current-actor="currentActor"
          :instance-name="instanceName"
        />
      </o-step-item>
    </o-steps>
    <section class="has-text-centered section buttons">
      <o-button
        outlined
        :disabled="stepIndex < 1"
        tag="router-link"
        :to="{
          name: RouteName.WELCOME_SCREEN,
          params: { step: stepIndex },
        }"
      >
        {{ $t("Previous") }}
      </o-button>
      <o-button
        outlined
        variant="success"
        v-if="stepIndex < 2"
        tag="router-link"
        :to="{
          name: RouteName.WELCOME_SCREEN,
          params: { step: stepIndex + 2 },
        }"
      >
        {{ $t("Next") }}
      </o-button>
      <o-button
        v-if="stepIndex >= 2"
        variant="success"
        size="big"
        tag="router-link"
        :to="{ name: RouteName.HOME }"
      >
        {{ $t("All good, let's continue!") }}
      </o-button>
    </section>
  </div>
</template>
<script lang="ts" setup>
import { USER_SETTINGS } from "@/graphql/user";
import { IUser } from "@/types/current-user.model";
import { useQuery } from "@vue/apollo-composable";
import { useHead } from "@vueuse/head";
import { computed, defineAsyncComponent, watch } from "vue";
import { useI18n } from "vue-i18n";
import RouteName from "@/router/name";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useInstanceName } from "@/composition/apollo/config";

const { currentActor } = useCurrentActorClient();
const { instanceName } = useInstanceName();
const { refetch } = useQuery<{ loggedUser: IUser }>(USER_SETTINGS);

const NotificationsOnboarding = defineAsyncComponent(
  () => import("@/components/Settings/NotificationsOnboarding.vue")
);
const SettingsOnboarding = defineAsyncComponent(
  () => import("@/components/Settings/SettingsOnboarding.vue")
);
const ProfileOnboarding = defineAsyncComponent(
  () => import("@/components/Account/ProfileOnboarding.vue")
);

const props = withDefaults(
  defineProps<{
    step?: number;
  }>(),
  {
    step: 1,
  }
);

const stepIndex = computed(() => props.step - 1);

watch(stepIndex, () => {
  refetch();
});

const { t } = useI18n({ useScope: "global" });
useHead({
  title: computed(() => t("First steps")),
});
</script>
<style scoped lang="scss">
.section.container {
  .has-text-centered.section.buttons {
    justify-content: center;
  }
}
</style>
