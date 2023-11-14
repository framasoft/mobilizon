<template>
  <o-dropdown aria-role="list" position="bottom-left">
    <template #trigger>
      <DotsHorizontal />
    </template>

    <o-dropdown-item
      aria-role="listitem"
      @click="$emit('rename')"
      class="inline-flex"
    >
      <Pencil />
      {{ $t("Rename") }}
    </o-dropdown-item>
    <o-dropdown-item aria-role="listitem" @click="$emit('move')">
      <FolderMove />
      {{ $t("Move") }}
    </o-dropdown-item>
    <o-dropdown-item aria-role="listitem" @click="$emit('delete')">
      <Delete />
      {{ $t("Delete") }}
    </o-dropdown-item>
  </o-dropdown>
</template>
<script lang="ts" setup>
import Pencil from "vue-material-design-icons/Pencil.vue";
import FolderMove from "vue-material-design-icons/FolderMove.vue";
import Delete from "vue-material-design-icons/Delete.vue";
import DotsHorizontal from "vue-material-design-icons/DotsHorizontal.vue";
</script>
