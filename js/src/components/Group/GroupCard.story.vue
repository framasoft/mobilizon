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
    url: "https://mobilizon.fr/media/7b340fe641e7ad711ebb6f8821b5ce824992db08701e37ebb901c175436aaafc.jpg?name=framasoft%27s%20banner.jpg",
  },
  avatar: {
    url: "https://mobilizon.fr/media/ff5b2d425fb73e17fcbb56a1a032359ee0b21453c11af59e103e783817a32fdf.png?name=framasoft%27s%20avatar.png",
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
