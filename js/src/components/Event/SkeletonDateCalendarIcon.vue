<template>
  <div
    class="datetime-container flex flex-col rounded-lg text-center justify-center overflow-hidden items-stretch bg-white dark:bg-gray-700 text-violet-3 dark:text-white"
  >
    <div class="datetime-container-content">
      <div class="ml-2 h-8 bg-slate-200 w-16"></div>
      <div class="ml-2 mt-2 h-4 bg-slate-200 w-16"></div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
div.datetime-container {
  width: calc(80px);
  box-shadow: 0 0 12px rgba(0, 0, 0, 0.2);
  height: calc(80px);
}
</style>
