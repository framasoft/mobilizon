<template>
  <div class="dark:text-white">
    <ShareModal
      :title="t('Share this event')"
      :text="event.title"
      :url="event.url"
      :input-label="t('Event URL')"
    >
      <o-notification
        variant="warning"
        v-if="event.visibility !== EventVisibility.PUBLIC"
        :closable="false"
      >
        {{
          $t(
            "This event is accessible only through it's link. Be careful where you post this link."
          )
        }}
      </o-notification>
      <o-notification
        variant="danger"
        v-if="event.status === EventStatus.CANCELLED"
        :closable="false"
      >
        {{ $t("This event has been cancelled.") }}
      </o-notification>
      <o-notification variant="warning" v-if="!eventCapacityOK">
        {{ $t("All the places have already been taken") }}
      </o-notification>
    </ShareModal>
  </div>
</template>

<script lang="ts" setup>
import { EventStatus, EventVisibility } from "@/types/enums";
import { useI18n } from "vue-i18n";
import { IEvent } from "@/types/event.model";
import ShareModal from "@/components/Share/ShareModal.vue";

withDefaults(
  defineProps<{
    event: IEvent;
    eventCapacityOK?: boolean;
  }>(),
  { eventCapacityOK: true }
);

const { t } = useI18n({ useScope: "global" });
</script>
