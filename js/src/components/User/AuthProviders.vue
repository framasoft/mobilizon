<template>
  <div>
    <b>{{ t("Sign in with") }}</b>
    <div class="flex gap-1 flex-wrap">
      <auth-provider
        v-for="provider in oauthProviders"
        :oauthProvider="provider"
        :key="provider.id"
      />
    </div>
  </div>
</template>
<script lang="ts" setup>
import { useI18n } from "vue-i18n";
import { IOAuthProvider } from "@/types/config.model";
import AuthProvider from "./AuthProvider.vue";

defineProps<{
  oauthProviders: IOAuthProvider[];
}>();

const { t } = useI18n({ useScope: "global" });
</script>
