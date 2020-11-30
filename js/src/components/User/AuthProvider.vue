<template>
  <a
    class="button is-light"
    v-if="isProviderSelected && oauthProvider.label === null"
    :href="`/auth/${oauthProvider.id}`"
  >
    <b-icon :icon="oauthProvider.id" />
    <span>{{ SELECTED_PROVIDERS[oauthProvider.id] }}</span></a
  >
  <a
    class="button is-light"
    :href="`/auth/${oauthProvider.id}`"
    v-else-if="isProviderSelected"
  >
    <b-icon icon="lock" />
    <span>{{ oauthProvider.label }}</span>
  </a>
</template>
<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { IOAuthProvider } from "../../types/config.model";
import { SELECTED_PROVIDERS } from "../../utils/auth";

@Component
export default class AuthProvider extends Vue {
  @Prop({ required: true, type: Object }) oauthProvider!: IOAuthProvider;

  SELECTED_PROVIDERS = SELECTED_PROVIDERS;

  get isProviderSelected(): boolean {
    return Object.keys(SELECTED_PROVIDERS).includes(this.oauthProvider.id);
  }
}
</script>
