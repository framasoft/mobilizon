<template>
  <p label-for="navSearchField" class="-mt-2">
    <input
      :placeholder="defaultPlaceHolder"
      type="search"
      id="navSearchField"
      icon="Magnify"
      icon-clickable
      rounded
      custom-class="searchField"
      dir="auto"
      v-model="search"
      @keyup.enter="enter"
    />
    <label>
      <span class="sr-only">{{ defaultPlaceHolder }}</span>
    </label>
  </p>
</template>
<script lang="ts" setup>
import { computed, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useRouter } from "vue-router";
import RouteName from "../router/name";

const router = useRouter();
const { t } = useI18n({ useScope: "global" });
const emit = defineEmits(["navbar-search"]);

const props = defineProps<{
  placeholder?: string;
}>();

const search = ref("");

const enter = async (): Promise<void> => {
  emit("navbar-search");
  await router.push({
    name: RouteName.SEARCH,
    query: { term: search.value },
  });
};

const defaultPlaceHolder = computed((): string => {
  // We can't use "this" inside @Prop's default value.
  return props.placeholder ?? t("Search");
});
</script>

<style lang="scss">
label span.visually-hidden {
  display: none;
}

input.searchField {
  box-shadow: none;
  border-color: #b5b5b5;
  border-radius: 9999px !important;

  &::placeholder {
    color: gray;
  }
}
</style>
