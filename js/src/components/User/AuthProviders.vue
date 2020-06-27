<template>
  <div>
    <b>{{ $t("Sign in with") }}</b>
    <div class="buttons">
      <auth-provider
        v-for="provider in oauthProviders"
        :oauthProvider="provider"
        :key="provider.id"
      />
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { IOAuthProvider } from "../../types/config.model";
import AuthProvider from "./AuthProvider.vue";

@Component({
  components: {
    AuthProvider,
  },
})
export default class AuthProviders extends Vue {
  @Prop({ required: true, type: Array }) oauthProviders!: IOAuthProvider[];
}
</script>
