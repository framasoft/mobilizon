<template>
  <Story>
    <Variant title="Public">
      <AuthProviders :oauthProviders="providers" />
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import AuthProviders from "./AuthProviders.vue";

const providers = [{ id: "keycloak", label: "Entreprise" }, { id: "google" }];
</script>
