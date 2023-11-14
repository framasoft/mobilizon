<template>
  <Story>
    <Variant title="Basic">
      <section class="flex flex-wrap gap-3 md:gap-5">
        <CategoryCard :category="category" />
      </section>
    </Variant>
    <Variant title="Details">
      <section class="flex flex-wrap gap-3 md:gap-5">
        <CategoryCard
          :category="{ ...category, key: 'OUTDOORS_ADVENTURE' }"
          :with-details="true"
        />
      </section>
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import { CategoryStatsModel } from "@/types/stats.model";
import { reactive } from "vue";
import CategoryCard from "./CategoryCard.vue";

const category = reactive<CategoryStatsModel>({
  key: "PHOTOGRAPHY",
  number: 5,
  label: "Hello",
});
</script>
