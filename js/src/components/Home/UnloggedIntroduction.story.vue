<template>
  <Story :setup-app="setupApp">
    <Variant :title="'Open'">
      <UnloggedIntroduction />
    </Variant>
    <Variant :title="'Closed'">
      <UnloggedIntroduction />
    </Variant>
  </Story>
</template>
<script lang="ts" setup>
import { apolloClient } from "@/vue-apollo";
import { DefaultApolloClient } from "@vue/apollo-composable";
import UnloggedIntroduction from "./UnloggedIntroduction.vue";

function setupApp({ app }) {
  app.provide(DefaultApolloClient, apolloClient);
}
</script>
