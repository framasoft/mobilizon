<template>
  <Story :setup-app="setupApp">
    <Variant>
      <SearchFields
        :search="''"
        :location="{}"
        @update:location="hstEvent('update location', $event)"
        @update:search="hstEvent('update search', $event)"
      />
    </Variant>
  </Story>
</template>
<script lang="ts" setup>
import { apolloClient } from "@/vue-apollo";
import { DefaultApolloClient } from "@vue/apollo-composable";
import SearchFields from "./SearchFields.vue";
import { hstEvent } from "histoire/client";

function setupApp({ app }) {
  app.provide(DefaultApolloClient, apolloClient);
}
</script>
