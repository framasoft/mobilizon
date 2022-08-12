<template>
  <form
    id="search-anchor"
    class="container mx-auto my-3 px-2 flex flex-wrap flex-col sm:flex-row items-stretch gap-2 text-center items-center justify-center dark:text-slate-100"
    role="search"
    @submit.prevent="emit('submit')"
  >
    <o-input
      class="flex-1"
      v-model="search"
      :placeholder="t('Keyword, event title, group name, etc.')"
      autofocus
      autocapitalize="off"
      autocomplete="off"
      autocorrect="off"
      maxlength="1024"
    />
    <full-address-auto-complete
      :type="AddressSearchType.ADMINISTRATIVE"
      :doGeoLocation="false"
      v-model="location"
    />
    <o-button type="submit" icon-left="magnify">
      <template v-if="search">{{ t("Go!") }}</template>
      <template v-else>{{ t("Explore!") }}</template>
    </o-button>
  </form>
</template>

<script lang="ts" setup>
import { IAddress } from "@/types/address.model";
import { AddressSearchType } from "@/types/enums";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import FullAddressAutoComplete from "@/components/Event/FullAddressAutoComplete.vue";

const props = defineProps<{
  location: IAddress;
  search: string;
}>();

const emit = defineEmits<{
  (event: "update:location", location: IAddress): void;
  (event: "update:search", newSearch: string): void;
  (event: "submit"): void;
}>();

const location = computed({
  get(): IAddress {
    return props.location;
  },
  set(newLocation: IAddress) {
    emit("update:location", newLocation);
  },
});

const search = computed({
  get(): string {
    return props.search;
  },
  set(newSearch: string) {
    emit("update:search", newSearch);
  },
});

const { t } = useI18n({ useScope: "global" });
</script>
<style scoped>
#search-anchor :deep(.o-ctrl-input) {
  flex: 1;
}
</style>
