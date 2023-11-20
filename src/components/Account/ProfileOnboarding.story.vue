<template>
  <Story>
    <Variant>
      <div class="p-5">
        <ProfileOnboarding
          :current-actor="baseActor"
          instance-name="Instance name"
        />
      </div>
    </Variant>
  </Story>
</template>

<script lang="ts" setup>
import ProfileOnboarding from "./ProfileOnboarding.vue";
import { ActorType } from "@/types/enums";
import { IPerson } from "@/types/actor";

const baseActor: IPerson = {
  name: "Thomas Citharel",
  preferredUsername: "tcit",
  avatar: null,
  domain: null,
  url: "",
  summary: "",
  suspended: false,
  type: ActorType.PERSON,
};
</script>
