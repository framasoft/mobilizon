<template>
  <div class="section container">
    <div class="setting-title">
      <h2>{{ $t("Profiles and federation") }}</h2>
    </div>
    <div>
      <p class="content">
        {{
          $t(
            "Mobilizon uses a system of profiles to compartiment your activities. You will be able to create as many profiles as you want."
          )
        }}
      </p>
      <hr />
      <p class="content">
        <span>
          {{
            $t(
              "Mobilizon is a federated software, meaning you can interact - depending on your admin's federation settings - with content from other instances, such as joining groups or events that were created elsewhere."
            )
          }}
        </span>
        <span
          v-html="
            $t(
              'This instance, <b>{instanceName} ({domain})</b>, hosts your profile, so remember its name.',
              {
                domain,
                instanceName: config.name,
              }
            )
          "
        />
      </p>
      <hr />
      <p class="content">
        {{
          $t(
            "If you are being asked for your federated indentity, it's composed of your username and your instance. For instance, the federated identity for your first profile is:"
          )
        }}
      </p>
      <div class="has-text-centered">
        <code>{{ `${currentActor.preferredUsername}@${domain}` }}</code>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { CONFIG } from "@/graphql/config";
import { IPerson } from "@/types/actor";
import { IConfig } from "@/types/config.model";
import { Component, Vue } from "vue-property-decorator";

@Component({
  apollo: {
    config: CONFIG,
    currentActor: CURRENT_ACTOR_CLIENT,
  },
})
export default class ProfileOnboarding extends Vue {
  config!: IConfig;

  currentActor!: IPerson;

  domain = window.location.hostname;
}
</script>
