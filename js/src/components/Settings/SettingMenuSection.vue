<template>
  <li class="bg-yellow-1 text-violet-2 text-xl">
    <router-link
      class="cursor-pointer my-2 mx-0 py-2 px-3 font-medium block no-underline"
      v-if="to"
      :to="to"
      >{{ title }}</router-link
    >
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
