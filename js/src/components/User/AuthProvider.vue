<template>
  <a
    class="button is-light"
    v-if="Object.keys(SELECTED_PROVIDERS).includes(oauthProvider.id)"
    :href="`/auth/${oauthProvider.id}`"
  >
    <b-icon :icon="oauthProvider.id" />
    <span>{{ SELECTED_PROVIDERS[oauthProvider.id] }}</span></a
  >
  <a class="button is-light" :href="`/auth/${oauthProvider.id}`" v-else>
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
}
</script>
