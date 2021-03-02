<template>
  <div class="container section">
    <h2 class="title">{{ $t("Privacy Policy") }}</h2>
    <div class="content" v-if="config" v-html="config.privacy.bodyHtml" />
  </div>
</template>

<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { PRIVACY } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import { InstancePrivacyType } from "@/types/enums";

@Component({
  apollo: {
    config: {
      query: PRIVACY,
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
export default class Privacy extends Vue {
  config!: IConfig;

  locale: string | null = null;

  created(): void {
    this.locale = this.$i18n.locale;
  }

  @Watch("config", { deep: true })
  watchConfig(config: IConfig): void {
    if (config?.privacy?.type) {
      this.redirectToUrl();
    }
  }

  redirectToUrl(): void {
    if (this.config?.privacy?.type === InstancePrivacyType.URL) {
      window.location.replace(this.config?.privacy?.url);
    }
  }
}
</script>
<style lang="scss" scoped>
main > .container {
  background: $white;

  ::v-deep dt {
    font-weight: bold;
  }
}
.content ::v-deep li {
  margin-bottom: 1rem;
}
</style>
