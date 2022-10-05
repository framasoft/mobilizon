<template>
  <router-link
    :to="{
      name: 'SEARCH',
      query: {
        categoryOneOf: [category.key],
        contentType: 'EVENTS',
        radius: undefined,
      },
    }"
    class="max-w-xs rounded-lg overflow-hidden bg-center bg-no-repeat bg-cover shadow-lg relative group"
  >
    <picture
      v-if="categoriesWithPictures.includes(category.key)"
      class="brightness-50"
    >
      <source
        :srcset="`/img/categories/${category.key.toLowerCase()}.webp 2x, /img/categories/${category.key.toLowerCase()}.webp`"
        media="(min-width: 1000px)"
      />
      <source
        :srcset="`/img/categories/${category.key.toLowerCase()}.webp 2x, /img/categories/${category.key.toLowerCase()}-small.webp`"
        media="(min-width: 300px)"
      />
      <img
        class="w-full h-36 w-36 md:h-52 md:w-52 object-cover"
        :src="`/img/categories/${category.key.toLowerCase()}.webp`"
        :srcset="`/img/categories/${category.key.toLowerCase()}-small.webp `"
        width="384"
        height="384"
        alt=""
        loading="lazy"
      />
    </picture>
    <p
      v-else
      class="h-36 w-36 md:h-52 md:w-52 brightness-75"
      :class="randomGradient()"
    />
    <div class="px-3 py-1 absolute left-0 bottom-0">
      <h2
        class="group-hover:text-slate-200 font-semibold text-white tracking-tight text-xl mb-3"
      >
        {{ category.label }}
      </h2>
    </div>
    <span
      v-if="withDetails"
      class="absolute z-10 inline-flex items-center px-3 py-1 text-xs font-semibold text-white bg-black rounded-full right-2 top-2"
    >
      {{
        t(
          "{count} events",
          {
            count: category.number.toString(),
          },
          category.number
        )
      }}
    </span>
  </router-link>
</template>
<script lang="ts" setup>
import { categoriesWithPictures } from "./constants";
import { randomGradient } from "../../utils/graphics";
import { CategoryStatsModel } from "../../types/stats.model";

import { useI18n } from "vue-i18n";

withDefaults(
  defineProps<{
    category: CategoryStatsModel;
    withDetails?: boolean;
  }>(),
  {
    withDetails: false,
  }
);

const { t } = useI18n({ useScope: "global" });
</script>
