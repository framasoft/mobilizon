<template>
  <p>
    <a :title="contact" v-if="configLink" :href="configLink.uri">{{
      configLink.text
    }}</a>
    <span v-else-if="contact">{{ contact }}</span>
    <span v-else>{{ $t("contact uninformed") }}</span>
  </p>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";

@Component
export default class InstanceContactLink extends Vue {
  @Prop({ required: true, type: String }) contact!: string;

  get configLink(): { uri: string; text: string } | null {
    if (!this.contact) return null;
    if (this.isContactEmail) {
      return {
        uri: `mailto:${this.contact}`,
        text: this.contact,
      };
    }
    if (this.isContactURL) {
      return {
        uri: this.contact,
        text:
          InstanceContactLink.urlToHostname(this.contact) ||
          (this.$t("Contact") as string),
      };
    }
    return null;
  }

  get isContactEmail(): boolean {
    return this.contact.includes("@");
  }

  get isContactURL(): boolean {
    return this.contact.match(/^https?:\/\//g) !== null;
  }

  static urlToHostname(url: string): string | null {
    try {
      return new URL(url).hostname;
    } catch (e) {
      return null;
    }
  }
}
</script>
