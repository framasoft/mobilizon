<template>
  <div class="">
    <h2 class="text-2xl">{{ t("Profiles and federation") }}</h2>
  </div>
  <p class="my-2">
    {{
      t(
        "Mobilizon uses a system of profiles to compartiment your activities. You will be able to create as many profiles as you want."
      )
    }}
  </p>
  <hr role="presentation" />
  <p class="my-2">
    <span>
      {{
        t(
          "Mobilizon is a federated software, meaning you can interact - depending on your admin's federation settings - with content from other instances, such as joining groups or events that were created elsewhere."
        )
      }}
    </span>
    <i18n-t
      keypath="This instance, {instanceName}, hosts your profile, so remember its name."
    >
      <template #instanceName>
        <b>{{
          t("{instanceName} ({domain})", {
            domain,
            instanceName,
          })
        }}</b>
      </template>
    </i18n-t>
  </p>
  <hr role="presentation" />
  <p class="my-2">
    {{
      t(
        "If you are being asked for your federated indentity, it's composed of your username and your instance. For instance, the federated identity for your first profile is:"
      )
    }}
  </p>
  <div class="text-center">
    <code>{{ `${currentActor?.preferredUsername}@${domain}` }}</code>
  </div>
</template>

<script lang="ts" setup>
import { IPerson } from "@/types/actor";
import { computed } from "vue";
import { useI18n } from "vue-i18n";

defineProps<{
  currentActor: IPerson;
  instanceName: string;
}>();

const { t } = useI18n({ useScope: "global" });

const domain = computed(() => window.location.hostname);
</script>
