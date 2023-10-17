<template>
  <Story>
    <Variant :setup-app="setupApp" title="Person">
      <div class="p-5">
        <PopoverActorCard :actor="baseActor">
          <div><b> Popover me !</b></div></PopoverActorCard
        >
      </div>
    </Variant>
    <Variant :setup-app="setupApp" title="Group">
      <div class="p-5">
        <PopoverActorCard :actor="group">
          <div><b> Popover me !</b></div></PopoverActorCard
        >
      </div>
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import PopoverActorCard from "./PopoverActorCard.vue";
import FloatingVue from "floating-vue";
import "floating-vue/dist/style.css";
import { ActorType } from "@/types/enums";

const baseActorAvatar = {
  id: "",
  name: "",
  alt: "",
  metadata: {},
  url: "https://social.tcit.fr/system/accounts/avatars/000/000/001/original/a28c50ce5f2b13fd.jpg",
};

const baseActor = {
  name: "Thomas Citharel",
  preferredUsername: "tcit",
  avatar: baseActorAvatar,
  domain: null,
  url: "",
  summary: "",
  suspended: false,
  type: ActorType.PERSON,
};

const group = {
  ...baseActor,
  name: "Framasoft",
  preferredUsername: "framasoft",
  domain: "mobilizon.fr",
  avatar: {
    ...baseActorAvatar,
    url: "https://stockage.framapiaf.org/framapiaf/accounts/avatars/000/000/399/original/52b08a3e80b43d40.jpg",
  },
};

function setupApp({ app }) {
  app.use(FloatingVue);
}
</script>
