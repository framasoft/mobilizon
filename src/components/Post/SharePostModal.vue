<template>
  <share-modal
    :title="t('Share this post')"
    :text="post.title"
    :url="post.url ?? ''"
    :input-label="t('Post URL')"
  >
    <o-notification
      variant="warning"
      v-if="post.visibility === PostVisibility.UNLISTED"
      :closable="false"
    >
      {{
        t(
          "This post is accessible only through it's link. Be careful where you post this link."
        )
      }}
    </o-notification>
  </share-modal>
</template>

<script lang="ts" setup>
import { PostVisibility } from "@/types/enums";
import { IPost } from "../../types/post.model";
import { useI18n } from "vue-i18n";
import ShareModal from "@/components/Share/ShareModal.vue";

defineProps<{
  post: IPost;
}>();

const { t } = useI18n({ useScope: "global" });
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
