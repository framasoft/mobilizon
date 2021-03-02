<template>
  <div class="container section">
    <h2 class="title">{{ $t("Terms") }}</h2>
    <div class="content" v-if="config" v-html="config.terms.bodyHtml" />
  </div>
</template>

<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { TERMS } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { InstanceTermsType } from "@/types/enums";

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

  created(): void {
    this.locale = this.$i18n.locale;
  }

  @Watch("config", { deep: true })
  watchConfig(config: IConfig): void {
    if (config?.terms?.type) {
      this.redirectToUrl();
    }
  }

  redirectToUrl(): void {
    if (this.config?.terms?.type === InstanceTermsType.URL) {
      window.location.replace(this.config?.terms?.url);
    }
  }
}
</script>
<style lang="scss" scoped>
.content ::v-deep li {
  margin-bottom: 1rem;
}
</style>
