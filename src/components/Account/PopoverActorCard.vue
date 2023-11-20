<template>
  <VMenu
    :distance="16"
    :triggers="['hover']"
    class="popover"
    :class="{ inline, clickable: actor && actor.type === ActorType.GROUP }"
  >
    <slot></slot>
    <template #popper>
      <actor-card :full="true" :actor="actor" :popover="true" />
    </template>
  </VMenu>
</template>
<script lang="ts" setup>
import { ActorType } from "@/types/enums";
import { IActor } from "../../types/actor";
import ActorCard from "./ActorCard.vue";

withDefaults(
  defineProps<{
    actor: IActor;
    inline?: boolean;
  }>(),
  {
    inline: false,
  }
);
</script>
