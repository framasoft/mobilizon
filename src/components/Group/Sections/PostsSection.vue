<template>
  <group-section
    :title="t('Announcements')"
    icon="bullhorn"
    :route="{
      name: RouteName.POSTS,
      params: { preferredUsername: usernameWithDomain(group) },
    }"
  >
    <template #default>
      <div class="p-1">
        <multi-post-list-item
          v-if="group?.posts?.total ?? 0 > 0"
          :posts="(group?.posts?.elements ?? []).slice(0, 3)"
          :isCurrentActorMember="isMember"
        />
        <empty-content v-else-if="group" icon="bullhorn" :inline="true">
          {{ t("No posts yet") }}
        </empty-content>
      </div>
    </template>
    <template #create>
      <o-button
        tag="router-link"
        v-if="isModerator"
        :to="{
          name: RouteName.POST_CREATE,
          params: { preferredUsername: usernameWithDomain(group) },
        }"
        class="button is-primary"
        >{{ t("+ Create a post") }}</o-button
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
import MultiPostListItem from "@/components/Post/MultiPostListItem.vue";
import GroupSection from "@/components/Group/GroupSection.vue";

const { t } = useI18n({ useScope: "global" });

defineProps<{ group: IGroup; isModerator: boolean; isMember: boolean }>();
</script>
