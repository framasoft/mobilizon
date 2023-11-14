<template>
  <div class="relative border overflow-hidden dark:border-transparent">
    <button
      class="block w-full text-start bg-white dark:bg-violet-1 border py-1 px-2 rounded dark:border-transparent"
      :class="{ 'border-black dark:!border-white': index === selectedIndex }"
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

const onKeyDown = ({ event }: { event: KeyboardEvent }): boolean => {
  if (event.key === "ArrowUp") {
    upHandler();
    return true;
  }

  if (event.key === "ArrowDown") {
    downHandler();
    return true;
  }

  if (event.key === "Enter") {
    enterHandler();
    return true;
  }

  return false;
};

const upHandler = (): void => {
  selectedIndex.value =
    (selectedIndex.value + props.items.length - 1) % props.items.length;
};

const downHandler = (): void => {
  selectedIndex.value = (selectedIndex.value + 1) % props.items.length;
};

const enterHandler = (): void => {
  selectItem(selectedIndex.value);
};

const selectItem = (index: number): void => {
  const item = props.items[index];

  if (item) {
    props.command({ id: usernameWithDomain(item) });
  }
};

defineExpose({
  onKeyDown,
});
</script>
