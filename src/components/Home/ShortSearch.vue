<template>
  <form
    id="short-search"
    class="container mx-auto my-3 px-2 flex flex-wrap flex-col sm:flex-row items-stretch gap-2 text-center justify-center dark:text-slate-100"
    role="search"
    @submit.prevent="submit"
  >
    <label class="sr-only" for="short_search_field_input">{{
      t("Keyword, event title, group name, etc.")
    }}</label>
    <o-input
      v-model="search"
      :placeholder="t('Keyword, event title, group name, etc.')"
      class="max-w-md"
      id="short_search_field_input"
      autofocus
      autocapitalize="off"
      autocomplete="off"
      autocorrect="off"
      maxlength="1024"
      expanded
    />
    <o-button
      class="search-Event min-w-40 mr-1 mb-1"
      native-type="submit"
      icon-left="magnify"
    >
      {{ t("Search") }}
    </o-button>
  </form>
</template>

<script lang="ts" setup>
import { useI18n } from "vue-i18n";
import { useRouter, useRoute } from "vue-router";
import { ref } from "vue";
import RouteName from "@/router/name";
const search = ref<string>("");

const router = useRouter();
const route = useRoute();

const submit = () => {
  const search_query = {
    search: search.value,
  };
  router.push({
    name: RouteName.SEARCH,
    query: {
      ...route.query,
      ...search_query,
    },
  });
};

const { t } = useI18n({ useScope: "global" });
</script>
