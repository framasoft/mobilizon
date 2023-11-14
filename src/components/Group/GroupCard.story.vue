<template>
  <Story>
    <Variant title="Empty">
      <div class="p-5">
        <GroupCard :group="basicGroup" />
      </div>
    </Variant>
    <Variant title="With media">
      <div class="p-5">
        <GroupCard :group="groupWithMedia" />
      </div>
    </Variant>
    <Variant title="with followers or members">
      <div class="p-5">
        <GroupCard :group="groupWithFollowersOrMembers" />
      </div>
    </Variant>
    <Variant title="Row mode">
      <GroupCard :group="groupWithFollowersOrMembers" mode="row" />
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import { IGroup } from "@/types/actor";
import GroupCard from "./GroupCard.vue";

const basicGroup: IGroup = {
  name: "Framasoft",
  preferredUsername: "framasoft",
  avatar: null,
  domain: "mobilizon.fr",
  url: "",
  summary: "",
  suspended: false,
  members: { total: 0, elements: [] },
  followers: { total: 0, elements: [] },
};

const groupWithMedia: IGroup = {
  ...basicGroup,
  banner: {
    url: "https://mobilizon.fr/media/a8227a16cc80b3d20ff5ee549a29c1b20a0ca1547f8861129aae9f00c3c69d12.jpg?name=framasoft%27s%20banner.jpg",
  },
  avatar: {
    url: "https://mobilizon.fr/media/890f5396ef80081a6b1b18a5db969746cf8bb340e8a4e657d665e41f6646c539.jpg?name=framasoft%27s%20avatar.jpg",
  },
};

const groupWithFollowersOrMembers: IGroup = {
  ...groupWithMedia,
  members: { total: 2, elements: [] },
  followers: { total: 5, elements: [] },
  summary:
    "You can also use variant modifiers to target media queries like responsive breakpoints, dark mode, prefers-reduced-motion, and more. For example, use md:h-full to apply the h-full utility at only medium screen sizes and above.",
  physicalAddress: {
    description: "Nantes",
  },
};
</script>
