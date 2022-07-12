<template>
  <Story>
    <Variant title="new">
      <TagInput v-model="tags" :fetch-tags="fetchTags" />
    </Variant>
    <!-- <Variant title="small">
      <TagInput v-model="tags" />
    </Variant> -->
  </Story>
</template>

<script lang="ts" setup>
import { ITag } from "@/types/tag.model";
import { reactive } from "vue";
import TagInput from "./TagInput.vue";

const tags = reactive<ITag[]>([{ title: "Hello", slug: "hello" }]);

const fetchTags = async (text: string) =>
  new Promise<ITag[]>((resolve, reject) => {
    resolve([{ title: "Welcome", slug: "welcome" }]);
  });
</script>
