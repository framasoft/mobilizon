<template>
  <Story>
    <Variant title="local">
      <ActorInline :actor="stateLocal" />
      <template #controls>
        <HstText v-model="stateLocal.preferredUsername" title="username" />
        <HstText v-model="stateLocal.name" title="Name" />
      </template>
    </Variant>
    <Variant title="remote">
      <ActorInline :actor="stateRemote" />
      <template #controls>
        <HstText v-model="stateRemote.preferredUsername" title="username" />
        <HstText v-model="stateRemote.name" title="Name" />
        <HstText v-model="stateRemote.domain" title="Domain" />
        <HstText v-model="avatarUrl" title="Avatar" />
      </template>
    </Variant>
  </Story>
</template>
<script lang="ts" setup>
import ActorInline from "./ActorInline.vue";
import { reactive, ref } from "vue";
import { IActor } from "@/types/actor";
import { ActorType } from "@/types/enums";

const avatarUrl = ref<string>(
  "https://stockage.framapiaf.org/framapiaf/accounts/avatars/000/000/399/original/52b08a3e80b43d40.jpg"
);

const stateLocal = reactive<IActor>({
  name: "Thomas Citharel",
  preferredUsername: "tcit",
  avatar: null,
  domain: null,
  url: "",
  summary: "",
  suspended: false,
  type: ActorType.PERSON,
});

const stateRemote = reactive<IActor>({
  name: "Framasoft",
  preferredUsername: "framasoft",
  avatar: { url: avatarUrl.value, id: "", name: "", alt: "", metadata: {} },
  domain: "framapiaf.org",
  url: "",
  summary: "",
  suspended: false,
  type: ActorType.PERSON,
});
</script>
