<template>
  <section class="container mx-auto py-4 is-max-desktop max-w-2xl">
    <div class="">
      <div class="">
        <h1 class="text-4xl mb-3">
          {{ $t("The page you're looking for doesn't exist.") }}
        </h1>
        <p>
          {{
            $t(
              "Please make sure the address is correct and that the page hasn't been moved."
            )
          }}
        </p>
        <p>
          {{
            $t(
              "Please contact this instance's Mobilizon admin if you think this is a mistake."
            )
          }}
        </p>
        <!--  The following should just be replaced with the SearchField component but it fails for some reason  -->
        <form @submit.prevent="enter" class="flex flex-wrap mt-3">
          <o-field expanded>
            <o-input
              expanded
              icon="magnify"
              type="search"
              :placeholder="searchPlaceHolder"
              v-model="searchText"
            />
            <p class="control">
              <button type="submit" class="button is-primary">
                {{ $t("Search") }}
              </button>
            </p>
          </o-field>
        </form>
      </div>
    </div>
  </section>
</template>
<script lang="ts" setup>
import { useHead } from "@/utils/head";
import { computed, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useRouter } from "vue-router";
import RouteName from "../router/name";

const searchText = ref("");

const { t } = useI18n({ useScope: "global" });
useHead({
  title: computed(() => t("Page not found")),
});
const router = useRouter();

const searchPlaceHolder = computed((): string => {
  return t("Search events, groups, etc.") as string;
});

const enter = async (): Promise<void> => {
  await router.push({
    name: RouteName.SEARCH,
    query: { term: searchText.value },
  });
};
</script>
