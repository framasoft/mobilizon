<template>
  <div class="items">
    <button
      class="item"
      :class="{ 'is-selected': index === selectedIndex }"
      v-for="(item, index) in items"
      :key="index"
      @click="selectItem(index)"
    >
      <actor-inline :actor="item" />
    </button>
  </div>
</template>

<script lang="ts" setup>
import { usernameWithDomain } from "@/types/actor/actor.model";
import { IPerson } from "@/types/actor";
import ActorInline from "../../components/Account/ActorInline.vue";
import { ref, watch } from "vue";

const props = defineProps<{
  items: IPerson[];
  command: ({ id }: { id: string }) => any;
}>();

// @Prop({ type: Function, required: true }) command!: any;

const selectedIndex = ref(0);

watch(
  () => props.items,
  () => {
    selectedIndex.value = 0;
  }
);

// const onKeyDown = ({ event }: { event: KeyboardEvent }): boolean => {
//   if (event.key === "ArrowUp") {
//     upHandler();
//     return true;
//   }

//   if (event.key === "ArrowDown") {
//     downHandler();
//     return true;
//   }

//   if (event.key === "Enter") {
//     enterHandler();
//     return true;
//   }

//   return false;
// };

// const upHandler = (): void => {
//   selectedIndex.value =
//     (selectedIndex.value + props.items.length - 1) % props.items.length;
// };

// const downHandler = (): void => {
//   selectedIndex.value = (selectedIndex.value + 1) % props.items.length;
// };

// const enterHandler = (): void => {
//   selectItem(selectedIndex.value);
// };

const selectItem = (index: number): void => {
  const item = props.items[index];

  if (item) {
    props.command({ id: usernameWithDomain(item) });
  }
};
</script>

<style lang="scss" scoped>
.items {
  position: relative;
  border-radius: 0.25rem;
  background: white;
  color: rgba(black, 0.8);
  overflow: hidden;
  font-size: 0.9rem;
  box-shadow:
    0 0 0 1px rgba(0, 0, 0, 0.1),
    0px 10px 20px rgba(0, 0, 0, 0.1);
}

.item {
  display: block;
  width: 100%;
  text-align: left;
  background: transparent;
  border: none;
  padding: 0.5rem 0.75rem;
}
</style>
