<template>
  <Story>
    <Variant title="Public">
      <PostListItem :post="post" />
    </Variant>

    <Variant title="Long">
      <PostListItem :post="longPost" />
    </Variant>

    <Variant title="Is member">
      <PostListItem :post="longPost" :is-current-actor-member="true" />
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import { IPost } from "@/types/post.model";
import PostListItem from "./PostListItem.vue";

const post: IPost = {
  title: "Musique sur Nantes : un groupe à développer ensemble !",
  url: "https://mobilizon.fr/p/an-uuid",
  insertedAt: new Date(),
  author: {
    name: "I'm the author",
    preferredUsername: "the_author",
  },
  tags: [
    { slug: "musique", title: "Musique" },
    { slug: "concert", title: "Concert" },
  ],
  picture: {
    url: "https://mobilizon.fr/media/70e930f488788afdf5d024be5ac2f9c9f0e1b166e16f645beb2c344cdcc65d62.jpg?name=musiquesurnantesbanner.jpg",
  },
};

const longPost = {
  ...post,
  title:
    "Musique sur Nantes : un groupe à développer ensemble ! Musique sur Nantes : un groupe à développer ensemble !",
  tags: [
    ...(post.tags ?? []),
    { slug: "verylongtagwhathappensthen", title: "VeryLongTagWhatHappensThen" },
    { slug: "justanother", title: "Just another" },
  ],
};
</script>
