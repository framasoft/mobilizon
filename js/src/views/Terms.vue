<template>
  <div class="container section">
    <h2 class="title">{{ $t("Privacy Policy") }}</h2>
    <div class="content" v-html="config.terms.bodyHtml" />
  </div>
</template>

<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { TERMS } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { InstanceTermsType } from "@/types/admin.model";
import RouteName from "../router/name";

@Component({
  apollo: {
    config: {
      query: TERMS,
      variables() {
        return {
          locale: this.locale,
        };
      },
      skip() {
        return !this.locale;
      },
    },
  },
})
export default class Terms extends Vue {
  config!: IConfig;

  locale: string | null = null;

  created() {
    this.locale = this.$i18n.locale;
  }

  @Watch("config", { deep: true })
  watchConfig(config: IConfig) {
    if (config.terms.type) {
      console.log(this.config.terms);
      this.redirectToUrl();
    }
  }

  redirectToUrl() {
    if (this.config.terms.type === InstanceTermsType.URL) {
      window.location.replace(this.config.terms.url);
    }
  }

  RouteName = RouteName;
}
</script>
<style lang="scss" scoped>
@import "@/variables.scss";

main > .container {
  background: $white;
}
</style>
