<template>
  <p>
    <a dir="auto" :title="contact" v-if="configLink" :href="configLink.uri">{{
      configLink.text
    }}</a>
    <span dir="auto" v-else-if="contact">{{ contact }}</span>
    <span v-else>{{ t("contact uninformed") }}</span>
  </p>
</template>
<script lang="ts" setup>
import { computed } from "vue";
import { useI18n } from "vue-i18n";

const props = defineProps<{
  contact?: string;
}>();

const { t } = useI18n({ useScope: "global" });

const configLink = computed((): { uri: string; text: string } | null => {
  if (!props.contact) return null;
  if (isContactEmail.value) {
    return {
      uri: `mailto:${props.contact}`,
      text: props.contact,
    };
  }
  if (isContactURL.value) {
    return {
      uri: props.contact,
      text: urlToHostname(props.contact) ?? "Contact",
    };
  }
  return null;
});

const isContactEmail = computed((): boolean => {
  return (props.contact ?? "").includes("@");
});

const isContactURL = computed((): boolean => {
  return (props.contact ?? "").match(/^https?:\/\//g) !== null;
});

const urlToHostname = (url: string): string | null => {
  try {
    return new URL(url).hostname;
  } catch (e) {
    return null;
  }
};
</script>
