<template>
  <Story :setup-app="setupApp">
    <Variant>
      <CategoriesPreview />
    </Variant>
  </Story>
</template>
<script lang="ts" setup>
import { apolloClient } from "@/vue-apollo";
import { DefaultApolloClient } from "@vue/apollo-composable";
import CategoriesPreview from "./CategoriesPreview.vue";

function setupApp({ app }) {
  app.provide(DefaultApolloClient, apolloClient);
}
</script>
