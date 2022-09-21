<template>
  <Story :setup-app="setupApp">
    <Variant>
      <OrganizerPicker
        v-model="actor"
        :identities="identities"
        v-model:actor-filter="actorFilter"
        :groupMemberships="[]"
        :current-actor="currentActor"
        @update:actor-filter="hstEvent('Actor Filter updated', $event)"
        @update:model-value="hstEvent('Selected actor updated', $event)"
      />
    </Variant>
  </Story>
</template>
<script lang="ts" setup>
import OrganizerPicker from "./OrganizerPicker.vue";
import { createMemoryHistory, createRouter } from "vue-router";
import { reactive, ref } from "vue";
import { ActorType } from "@/types/enums";
import { hstEvent } from "histoire/client";

const currentActor = reactive({
  id: "59",
  preferredUsername: "me",
  name: "Someone",
  type: ActorType.PERSON,
});

const actor = reactive({
  id: "5",
  preferredUsername: "hello",
  name: "Sigmund",
  type: ActorType.PERSON,
});

const group = reactive({
  id: "89",
  preferredUsername: "congregation",
  name: "College",
  type: ActorType.GROUP,
});

const identities = [actor, group];

const actorFilter = ref("");

function setupApp({ app }) {
  app.use(
    createRouter({
      history: createMemoryHistory(),
      routes: [{ path: "/", name: "home", component: { render: () => null } }],
    })
  );
}
</script>
