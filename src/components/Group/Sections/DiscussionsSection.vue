<template>
  <group-section
    :title="t('Discussions')"
    icon="chat"
    :route="{
      name: RouteName.DISCUSSION_LIST,
      params: { preferredUsername: usernameWithDomain(group) },
    }"
  >
    <template #default>
      <div v-if="group?.discussions?.total ?? 0 > 0">
        <discussion-list-item
          v-for="discussion in group?.discussions?.elements ?? []"
          :key="discussion.id"
          :discussion="discussion"
        />
      </div>
      <empty-content v-else icon="chat" :inline="true">
        {{ t("No discussions yet") }}
      </empty-content>
    </template>
    <template #create>
      <o-button
        tag="router-link"
        :to="{
          name: RouteName.CREATE_DISCUSSION,
          params: { preferredUsername: usernameWithDomain(group) },
        }"
        class="button is-primary"
        >{{ t("+ Start a discussion") }}</o-button
      >
    </template>
  </group-section>
</template>

<script lang="ts" setup>
import RouteName from "@/router/name";
import { IGroup } from "@/types/actor/group.model";
import { usernameWithDomain } from "@/types/actor";
import { useI18n } from "vue-i18n";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import DiscussionListItem from "@/components/Discussion/DiscussionListItem.vue";
import GroupSection from "@/components/Group/GroupSection.vue";

const { t } = useI18n({ useScope: "global" });

defineProps<{
  group: Pick<IGroup, "preferredUsername" | "domain" | "discussions">;
}>();
</script>
