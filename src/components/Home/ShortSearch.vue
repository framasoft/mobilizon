<template>
  <form
    id="short-search"
    class="container mx-auto p-2 flex flex-wrap flex-col sm:flex-row items-stretch gap-2 justify-center dark:text-slate-100"
    role="search"
    @submit.prevent="submit"
  >
    <label class="sr-only" for="short_search_field_input">{{
      t("Keyword, event title, group name, etc.")
    }}</label>
    <div class="flex-auto sm:max-w-xl">
      <o-input
        v-model="search"
        :placeholder="t('Keyword, event title, group name, etc.')"
        id="short_search_field_input"
        autofocus
        autocapitalize="off"
        autocomplete="off"
        autocorrect="off"
        maxlength="1024"
        expanded
      />
    </div>
    <o-button
      class="search-Event min-w-40 sm:w-auto"
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
