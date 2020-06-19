<template>
  <div class="container section" v-if="config">
    <h2 class="title">{{ $t("Rules") }}</h2>
    <div class="content" v-html="config.rules" v-if="config.rules" />
    <p v-else>{{ $t("No rules defined yet.") }}</p>
  </div>
</template>

<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { RULES } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { InstanceTermsType } from "@/types/admin.model";
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
@import "@/variables.scss";

main > .container {
  background: $white;
}
.content /deep/ li {
  margin-bottom: 1rem;
}
</style>
