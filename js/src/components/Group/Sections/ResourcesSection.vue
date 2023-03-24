<template>
  <group-section
    :title="t('Resources')"
    icon="link"
    :route="{
      name: RouteName.RESOURCE_FOLDER_ROOT,
      params: { preferredUsername: usernameWithDomain(group) },
    }"
  >
    <template #default>
      <div v-if="group?.resources?.elements?.length ?? 0 > 0" class="p-1">
        <div
          v-for="resource in group?.resources?.elements ?? []"
          :key="resource.id"
        >
          <resource-item
            :resource="resource"
            v-if="resource.type !== 'folder'"
            :inline="true"
          />
          <folder-item
            :resource="resource"
            :group="group"
            v-else-if="group"
            :inline="true"
          />
        </div>
      </div>
      <empty-content v-else icon="link" :inline="true">
        {{ t("No resources yet") }}
      </empty-content>
    </template>
    <template #create>
      <o-button
        tag="router-link"
        :to="{
          name: RouteName.RESOURCE_FOLDER_ROOT,
          params: { preferredUsername: usernameWithDomain(group) },
        }"
        class="button is-primary"
        >{{ t("+ Add a resource") }}</o-button
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
import ResourceItem from "@/components/Resource/ResourceItem.vue";
import FolderItem from "@/components/Resource/FolderItem.vue";
import GroupSection from "@/components/Group/GroupSection.vue";

const { t } = useI18n({ useScope: "global" });

defineProps<{
  group: Pick<IGroup, "preferredUsername" | "domain" | "resources">;
}>();
</script>
