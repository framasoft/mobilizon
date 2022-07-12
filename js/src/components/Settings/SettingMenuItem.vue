<template>
  <li class="setting-menu-item" :class="{ active: isActive }">
    <router-link v-if="to" :to="to">
      <span>{{ title }}</span>
    </router-link>
    <span v-else>{{ title }}</span>
  </li>
</template>
<script lang="ts" setup>
import { computed } from "vue";
import { useRoute } from "vue-router";

const props = defineProps<{
  title?: string;
  to: { name: string; params?: Record<string, any> };
}>();

const route = useRoute();

const isActive = computed((): boolean => {
  if (props.to.name === route.name) {
    if (props.to.params) {
      return props.to.params.identityName === route.params.identityName;
    }
    return true;
  }
  return false;
});
</script>

<style lang="scss" scoped>
li.setting-menu-item {
  font-size: 1.05rem;
  background-color: #fff1de;
  color: $background-color;
  margin: auto;

  span {
    padding: 5px 15px;
    display: block;
  }

  a {
    display: block;
    color: inherit;
  }

  &:hover,
  &.active {
    cursor: pointer;
    background-color: lighten(#fea72b, 10%);
  }
}
</style>
