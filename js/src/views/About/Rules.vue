<template>
  <div class="container section" v-if="config">
    <h2 class="title">{{ $t("Rules") }}</h2>
    <div class="content" v-html="config.rules" v-if="config.rules" />
    <p v-else>{{ $t("No rules defined yet.") }}</p>
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { RULES } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import RouteName from "../../router/name";

@Component({
  apollo: {
    config: {
      query: RULES,
    },
  },
})
export default class Rules extends Vue {
  config!: IConfig;

  RouteName = RouteName;
}
</script>
<style lang="scss" scoped>
main > .container {
  background: $white;
}
.content ::v-deep li {
  margin-bottom: 1rem;
}
</style>
