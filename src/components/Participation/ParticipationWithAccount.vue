<template>
  <redirect-with-account
    v-if="uri"
    :uri="uri"
    :pathAfterLogin="`/events/${uuid}`"
    :sentence="sentence"
  />
</template>
<script lang="ts" setup>
import RedirectWithAccount from "@/components/Utils/RedirectWithAccount.vue";
import { useFetchEvent } from "@/composition/apollo/event";
import { useHead } from "@vueuse/head";
import { computed } from "vue";
import { useI18n } from "vue-i18n";

const props = defineProps<{
  uuid: string;
}>();

const { event } = useFetchEvent(computed(() => props.uuid));

const { t } = useI18n({ useScope: "global" });

useHead({
  title: computed(() => t("Participation with account")),
  meta: [{ name: "robots", content: "noindex" }],
});

const uri = computed((): string | undefined => {
  return event.value?.url;
});

const sentence = t(
  "We will redirect you to your instance in order to interact with this event"
);
</script>
