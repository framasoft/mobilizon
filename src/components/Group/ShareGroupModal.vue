<template>
  <share-modal
    :title="t('Share this group')"
    :text="displayName(group)"
    :url="group.url"
    :input-label="t('Group URL')"
  >
    <o-notification
      variant="warning"
      v-if="group.visibility !== GroupVisibility.PUBLIC"
      :closable="false"
    >
      {{
        $t(
          "This group is accessible only through it's link. Be careful where you post this link."
        )
      }}
    </o-notification>
  </share-modal>
</template>

<script lang="ts" setup>
import { GroupVisibility } from "@/types/enums";
import { displayName, IGroup } from "@/types/actor";
import { useI18n } from "vue-i18n";
import ShareModal from "@/components/Share/ShareModal.vue";

const { t } = useI18n({ useScope: "global" });

defineProps<{
  group: IGroup;
}>();
</script>
<style lang="scss" scoped>
.diaspora,
.mastodon,
.telegram {
  :deep(span svg) {
    width: 2.25rem;
  }
}
</style>
