<template>
  <Story>
    <Variant title="Public">
      <SharePostModal :post="{ ...post, visibility: PostVisibility.PUBLIC }" />
    </Variant>
    <Variant title="Private">
      <SharePostModal :post="post" />
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import { PostVisibility } from "@/types/enums";
import SharePostModal from "./SharePostModal.vue";

const post = {
  title: "hello",
  url: "https://mobilizon.fr/p/an-uuid",
};
</script>
