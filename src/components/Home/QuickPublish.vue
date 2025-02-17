<template>
  <div class="quick-publish flex justify-end">
    <o-button @click="$router.push({ name: ActorRouteName.MY_GROUPS })">
      {{ t("Publish") }}
    </o-button>
    <o-dropdown position="bottom-right">
      <template #trigger="{ active }">
        <o-button
          :title="t('Choose publishing')"
          :icon-right="active ? 'menu-up' : 'menu-down'"
        >
        </o-button>
      </template>
      <o-dropdown-item
        :label="t('Publish from a group')"
        @click="$router.push({ name: ActorRouteName.MY_GROUPS })"
      />
      <o-dropdown-item
        :label="t('Publish as individual')"
        @click="$router.push({ name: EventRouteName.CREATE_EVENT })"
      />
    </o-dropdown>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "vue-i18n";
import { ActorRouteName } from "@/router/actor";
import { EventRouteName } from "@/router/event";
const { t } = useI18n({ useScope: "global" });
</script>
<style scoped>
.quick-publish > div.o-drop {
  left: -5px;
}
</style>
