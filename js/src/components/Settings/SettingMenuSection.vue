<template>
  <li>
    <router-link v-if="to" :to="to">{{ title }}</router-link>
    <b v-else>{{ title }}</b>
    <ul>
      <slot></slot>
    </ul>
  </li>
</template>
<script lang="ts" setup>
defineProps<{
  title?: string;
  to: { name: string; params?: Record<string, any> };
}>();

// const route = useRoute();
// const slots = useSlots();

// const sectionActive = computed((): boolean => {
//   if (slots.default) {
//     return slots.default.some(
//       ({
//         componentOptions: {
//           propsData: { to },
//         },
//       }) => to && to.name === route.name
//     );
//   }
//   return false;
// });
</script>

<style lang="scss" scoped>
li {
  font-size: 1.3rem;
  background-color: $secondary;
  color: $background-color;
  margin: 2px auto;

  &.active {
    background-color: #fea72b;
  }

  a,
  b {
    cursor: pointer;
    margin: 5px 0;
    display: block;
    padding: 5px 10px;
    color: inherit;
    font-weight: 500;
  }
}
</style>
