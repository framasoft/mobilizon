<template>
  <share-modal
    :title="t('Share this post')"
    :text="post.title"
    :url="postURL"
    :input-label="t('Post URL')"
  >
    <o-notification
      variant="warning"
      v-if="post.visibility !== PostVisibility.PUBLIC"
      :closable="false"
    >
      {{
        $t(
          "This post is accessible only through it's link. Be careful where you post this link."
        )
      }}
    </o-notification>
  </share-modal>
</template>

<script lang="ts" setup>
import { PostVisibility } from "@/types/enums";
import { IPost } from "../../types/post.model";
import RouteName from "@/router/name";
import { computed } from "vue";
import { useRouter } from "vue-router";
import { useI18n } from "vue-i18n";
import ShareModal from "@/components/Share/ShareModal.vue";

const props = defineProps<{
  post: IPost;
}>();

const { t } = useI18n({ useScope: "global" });

const router = useRouter();

const postURL = computed((): string => {
  if (props.post.id) {
    return router.resolve({
      name: RouteName.POST,
      params: { id: props.post.id },
    }).href;
  }
  return props.post.url ?? "";
});
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
