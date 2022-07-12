<template>
  <section
    class="mx-auto container flex flex-wrap items-center justify-center gap-3 md:gap-5 my-3"
  >
    <CategoryCard
      v-for="category in promotedCategories"
      :key="category.key"
      :category="category"
      :with-details="false"
    />
    <router-link :to="{ name: RouteName.CATEGORIES }">
      <div
        class="flex items-end brightness-85 h-36 w-36 md:h-52 md:w-52 rounded-lg font-semibold text-lg md:text-xl p-4 text-white bg-gradient-to-r from-pink-500 via-red-500 to-yellow-500"
      >
        <span>
          {{ t("View all categories") }}
        </span>
      </div>
    </router-link>
  </section>
</template>
<script lang="ts" setup>
import { useQuery } from "@vue/apollo-composable";
import { computed } from "vue";
import CategoryCard from "../Categories/CategoryCard.vue";
import RouteName from "@/router/name";
import { CategoryStatsModel } from "@/types/stats.model";
import { CATEGORY_STATISTICS } from "@/graphql/statistics";
import { useI18n } from "vue-i18n";
import shuffle from "lodash/shuffle";
import { categoriesWithPictures } from "../Categories/constants";
import { IConfig } from "@/types/config.model";
import { CONFIG } from "@/graphql/config";

const { t } = useI18n({ useScope: "global" });

const { result: categoryStatsResult } = useQuery<{
  categoryStatistics: CategoryStatsModel[];
}>(CATEGORY_STATISTICS);
const categoryStats = computed(
  () => categoryStatsResult.value?.categoryStatistics ?? []
);

const { result: configResult } = useQuery<{ config: IConfig }>(CONFIG);

const config = computed(() => configResult.value?.config);

const eventCategories = computed(() => config.value?.eventCategories ?? []);

const eventCategoryLabel = (categoryId: string): string | undefined => {
  return eventCategories.value.find(({ id }) => categoryId == id)?.label;
};

const promotedCategories = computed((): CategoryStatsModel[] => {
  return shuffle(
    categoryStats.value.filter(
      ({ key, number }) =>
        key !== "MEETING" && number >= 1 && categoriesWithPictures.includes(key)
    )
  )
    .map(({ key, number }) => ({
      key,
      number,
      label: eventCategoryLabel(key),
    }))
    .slice(0, 10);
});
</script>
