<template>
  <o-button
    tag="a"
    outlined
    variant="primary"
    :icon-left="oauthProvider.id"
    v-if="isProviderSelected && !oauthProvider.label"
    :href="`/auth/${oauthProvider.id}`"
  >
    <span>{{ SELECTED_PROVIDERS[oauthProvider.id] }}</span></o-button
  >
  <o-button
    tag="a"
    outlined
    variant="primary"
    :href="`/auth/${oauthProvider.id}`"
    v-else-if="isProviderSelected"
    icon-left="lock"
  >
    <span>{{ oauthProvider.label }}</span>
  </o-button>
</template>
<script lang="ts" setup>
import { computed } from "vue";
import { IOAuthProvider } from "@/types/config.model";
import { SELECTED_PROVIDERS } from "@/utils/auth";

const props = defineProps<{
  oauthProvider: IOAuthProvider;
}>();

const isProviderSelected = computed((): boolean => {
  return Object.keys(SELECTED_PROVIDERS).includes(props.oauthProvider.id);
});
</script>
