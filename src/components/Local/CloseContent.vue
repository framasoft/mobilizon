<template>
  <div class="relative pt-10 px-2">
    <div class="mb-2">
      <div class="w-full flex flex-wrap gap-3 items-center">
        <h2
          class="text-xl font-bold tracking-tight text-gray-900 dark:text-gray-100 mt-0"
        >
          <slot name="title" />
        </h2>
      </div>
      <slot name="subtitle" />
    </div>
    <div class="" v-show="showScrollLeftButton">
      <button
        @click="scrollLeft"
        class="arrow absolute inset-y-0 my-auto z-30 rounded-full bg-white dark:bg-violet-2 w-10 h-10 border border-shadowColor -left-5 ml-2"
      >
        <span class="">&lt;</span>
      </button>
    </div>
    <div class="overflow-hidden">
      <div
        class="relative w-full snap-x snap-always snap-mandatory overflow-x-auto flex pb-6 gap-x-5 gap-y-8 p-1"
        ref="scrollContainer"
        @scroll="scrollHandler"
      >
        <slot name="content" />
      </div>
    </div>
    <div class="" v-show="showScrollRightButton">
      <button
        @click="scrollRight"
        class="arrow absolute inset-y-0 my-auto z-30 rounded-full bg-white dark:bg-violet-2 w-10 h-10 border border-shadowColor -right-5 mr-2"
      >
        <span class="">&gt;</span>
      </button>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { onMounted, onUnmounted, ref } from "vue";

withDefaults(
  defineProps<{
    suggestGeoloc?: boolean;
    doingGeoloc?: boolean;
  }>(),
  { suggestGeoloc: true, doingGeoloc: false }
);

const showScrollRightButton = ref(false);
const showScrollLeftButton = ref(false);

const scrollContainer = ref<any>();

const scrollHandler = () => {
  if (scrollContainer.value) {
    showScrollRightButton.value =
      scrollContainer.value.scrollLeft <
      scrollContainer.value.scrollWidth - scrollContainer.value.clientWidth;
    showScrollLeftButton.value = scrollContainer.value.scrollLeft > 0;
  }
};

const doScroll = (e: Event, left: number) => {
  e.preventDefault();
  if (scrollContainer.value) {
    scrollContainer.value.scrollBy({
      left,
      behavior: "smooth",
    });
  }
};

const scrollLeft = (e: Event) => {
  doScroll(e, -300);
};

const scrollRight = (e: Event) => {
  doScroll(e, 300);
};

const scrollHorizontalToVertical = (evt: WheelEvent) => {
  evt.deltaY > 0 ? doScroll(evt, 300) : doScroll(evt, -300);
};

onMounted(async () => {
  // Make sure everything is mounted properly
  setTimeout(() => {
    scrollHandler();
  }, 1500);
  scrollContainer.value.addEventListener("wheel", scrollHorizontalToVertical);
});

onUnmounted(() => {
  if (scrollContainer.value) {
    scrollContainer.value.removeEventListener(
      "wheel",
      scrollHorizontalToVertical
    );
  }
});
</script>
<style scoped>
.arrow {
  border-width: 2.5px;
  scale: 1.2;
}
</style>
