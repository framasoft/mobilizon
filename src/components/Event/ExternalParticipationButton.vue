<template>
  <o-button
    tag="a"
    :href="
      event.externalParticipationUrl
        ? encodeURI(`${event.externalParticipationUrl}?uuid=${event.uuid}`)
        : '#'
    "
    rel="noopener ugc"
    target="_blank"
    :disabled="!event.externalParticipationUrl"
    icon-right="OpenInNew"
  >
    {{ t("Go to booking") }}
  </o-button>
</template>

<script lang="ts" setup>
import { computed } from "vue";
import { IEvent } from "../../types/event.model";
import { useI18n } from "vue-i18n";

const { t } = useI18n({ useScope: "global" });

const props = defineProps<{
  event: IEvent;
}>();

const event = computed(() => props.event);
</script>
