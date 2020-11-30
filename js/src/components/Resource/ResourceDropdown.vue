<template>
  <b-dropdown aria-role="list" position="is-bottom-left">
    <b-icon icon="dots-horizontal" slot="trigger" />

    <b-dropdown-item aria-role="listitem" @click="$emit('rename')">
      <b-icon icon="pencil" />
      {{ $t("Rename") }}
    </b-dropdown-item>
    <b-dropdown-item aria-role="listitem" @click="$emit('move')">
      <b-icon icon="folder-move" />
      {{ $t("Move") }}
    </b-dropdown-item>
    <b-dropdown-item aria-role="listitem" @click="$emit('delete')">
      <b-icon icon="delete" />
      {{ $t("Delete") }}
    </b-dropdown-item>
  </b-dropdown>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";

@Component
export default class ResourceDropdown extends Vue {}
</script>
