<template>
  <Story>
    <Variant title="new">
      <TagInput v-model="tags" />
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
</script>
