<template>
  <div class="container mx-auto py-4 md:py-12 px-2 md:px-60">
    <main>
      <div class="flex flex-wrap items-center justify-center gap-3 md:gap-4">
        <CategoryCard
          v-for="category in promotedCategories"
          :key="category.key"
          :category="category"
          :with-details="true"
        />
      </div>

      <div
        class="mx-auto w-full max-w-lg rounded-2xl dark:bg-gray-800 p-2 mt-10"
      >
        <div
          class="card"
          animation="slide"
          :open="isLicencePanelOpen"
          @open="isLicencePanelOpen = !isLicencePanelOpen"
          :aria-id="'contentIdForA11y5'"
        >
          <div>
            <button
              class="flex w-full justify-between rounded-lg px-4 py-2 text-left text-sm font-medium dark:text-zinc-300"
            >
              {{ t("Category illustrations credits") }}
              <svg
                width="24"
                height="24"
                :class="isLicencePanelOpen ? 'transform rotate-90' : ''"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth="{2}"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M9 5l7 7-7 7"
                />
              </svg>
            </button>
          </div>
          <div class="flex flex-col dark:text-zinc-300 gap-2 py-4 px-1">
            <p
              v-for="(categoryLicence, key) in categoriesPicturesLicences"
              :key="key"
              class="flex flex-row gap-1 items-center"
            >
              <a
                :href="categoryLicence.source.url"
                target="_blank"
                class="shrink-0"
              >
                <picture class="brightness-50">
                  <source
                    :srcset="`/img/categories/${key.toLowerCase()}.webp 2x, /img/categories/${key.toLowerCase()}.webp`"
                    media="(min-width: 1000px)"
                  />
                  <source
                    :srcset="`/img/categories/${key.toLowerCase()}.webp 2x, /img/categories/${key.toLowerCase()}-small.webp`"
                    media="(min-width: 300px)"
                  />
                  <img
                    loading="lazy"
                    class="w-full h-12 w-12 object-cover"
                    :src="`/img/categories/${key.toLowerCase()}.webp`"
                    :srcset="`/img/categories/${key.toLowerCase()}-small.webp `"
                    alt=""
                  />
                </picture>
              </a>
              <span
                class="flex-0"
                v-html="
                  t(
                    'Illustration picture for “{category}” by {author} on {source} ({license})',
                    {
                      category: eventCategoryLabel(key),
                      author: imageAuthor(categoryLicence.author),
                      source: imageSource(categoryLicence.source),
                      license: imageLicense(categoryLicence),
                    }
                  )
                "
              />
            </p>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>
<script lang="ts" setup>
import CategoryCard from "@/components/Categories/CategoryCard.vue";

import { computed, ref } from "vue";
import { CATEGORY_STATISTICS } from "@/graphql/statistics";
import { useQuery } from "@vue/apollo-composable";
import { CategoryStatsModel } from "@/types/stats.model";
import {
  categoriesPicturesLicences,
  CategoryPictureLicencing,
  CategoryPictureLicencingElement,
} from "@/components/Categories/constants";
import { useI18n } from "vue-i18n";
import { useEventCategories } from "@/composition/apollo/config";

const { t } = useI18n({ useScope: "global" });

const { eventCategories } = useEventCategories();

const eventCategoryLabel = (categoryId: string): string | undefined => {
  return eventCategories.value?.find(({ id }) => categoryId == id)?.label;
};

const { result: categoryStatsResult } = useQuery<{
  categoryStatistics: CategoryStatsModel[];
}>(CATEGORY_STATISTICS);
const categoryStats = computed(
  () => categoryStatsResult.value?.categoryStatistics ?? []
);

const promotedCategories = computed((): CategoryStatsModel[] => {
  return categoryStats.value
    .map(({ key, number }) => ({
      key,
      number,
      label: eventCategoryLabel(key) as string,
    }))
    .filter(
      ({ key, number, label }) =>
        key !== "MEETING" && number >= 1 && label !== undefined
    )
    .sort((a, b) => a.label.localeCompare(b.label));
});

const imageAuthor = (author: CategoryPictureLicencingElement) =>
  `<a target="_blank" class="underline font-medium" href="${author?.url}">${author?.name}</a>`;
const imageSource = (source: CategoryPictureLicencingElement) =>
  `<a target="_blank" class="underline font-medium" href="${source?.url}">${source?.name}</a>`;

const imageLicense = (categoryLicence: CategoryPictureLicencing): string => {
  let license = categoryLicence?.license;
  if (categoryLicence?.source?.name === "Unsplash") {
    license = {
      name: "Unsplash License",
      url: "https://unsplash.com/license",
    };
  }
  return `<a target="_blank" class="underline font-medium" href="${license?.url}">${license?.name}</a>`;
};

const isLicencePanelOpen = ref(false);
</script>
