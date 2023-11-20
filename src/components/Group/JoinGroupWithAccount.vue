<template>
  <redirect-with-account
    v-if="uri"
    :uri="uri"
    :pathAfterLogin="`/@${preferredUsername}`"
    :sentence="
      t(
        `We will redirect you to your instance in order to interact with this group`
      )
    "
  />
</template>
<script lang="ts" setup>
import RedirectWithAccount from "@/components/Utils/RedirectWithAccount.vue";
import { useGroup } from "@/composition/apollo/group";
import { displayName } from "@/types/actor";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { useHead } from "@vueuse/head";

const props = defineProps<{
  preferredUsername: string;
}>();

const { group } = useGroup(computed(() => props.preferredUsername));

const { t } = useI18n({ useScope: "global" });

const groupTitle = computed((): undefined | string => {
  return group && displayName(group.value);
});

const uri = computed((): string | undefined => {
  return group.value?.url;
});

useHead({
  title: computed(() =>
    t("Join group {group}", {
      group: groupTitle.value,
    })
  ),
});
</script>
