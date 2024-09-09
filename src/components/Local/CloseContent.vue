<template>
  <div class="relative pt-10 px-2">
    <div class="mb-2">
      <div class="w-full flex flex-wrap gap-3 items-center">
        <h2
          class="text-xl font-bold tracking-tight text-gray-900 dark:text-gray-100 mt-0"
        >
          <slot name="title" />
        </h2>

        <o-button
          :disabled="doingGeoloc"
          v-if="suggestGeoloc"
          class="inline-flex bg-primary rounded text-white flex-initial px-4 py-2 justify-center w-full md:w-min whitespace-nowrap"
          @click="emit('doGeoLoc')"
        >
          {{ t("Geolocate me") }}
        </o-button>
      </div>
      <slot name="subtitle" />
    </div>

    <div
      class="grid auto-rows-[1fr] gap-x-2 gap-y-2 grid-cols-[repeat(auto-fill,_minmax(250px,_1fr))] justify-items-center"
    >
      <slot name="content" />
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "vue-i18n";

withDefaults(
  defineProps<{
    suggestGeoloc?: boolean;
    doingGeoloc?: boolean;
  }>(),
  { suggestGeoloc: true, doingGeoloc: false }
);

const emit = defineEmits(["doGeoLoc"]);

const { t } = useI18n({ useScope: "global" });
</script>
