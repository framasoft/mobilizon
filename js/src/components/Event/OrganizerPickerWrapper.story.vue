<template>
  <Story :setup-app="setupApp">
    <Variant>
      <OrganizerPickerWrapper
        v-model="actor"
        @update:model-value="hstEvent('Value', $event)"
        @update:contacts="hstEvent('Contacts', $event)"
      />
    </Variant>
  </Story>
</template>
<script lang="ts" setup>
import OrganizerPickerWrapper from "./OrganizerPickerWrapper.vue";
import { DefaultApolloClient } from "@vue/apollo-composable";
import { createMockClient } from "mock-apollo-client";
import { cache } from "@/apollo/memory";
import { ICurrentUserRole } from "@/types/enums";
import { PERSON_GROUP_MEMBERSHIPS } from "@/graphql/actor";
import { createMemoryHistory, createRouter } from "vue-router";
import { IDENTITIES } from "@/graphql/actor";
import { reactive } from "vue";
import { hstEvent } from "histoire/client";

const actor = reactive({
  id: "5",
  preferredUsername: "hello",
  name: "Sigmund",
});

function setupApp({ app }) {
  const defaultResolvers = {
    Query: {
      currentUser: (): Record<string, any> => ({
        email: "user@mail.com",
        id: "2",
        role: ICurrentUserRole.USER,
        isLoggedIn: true,
        __typename: "CurrentUser",
      }),
      currentActor: (): Record<string, any> => ({
        id: "67",
        preferredUsername: "someone",
        name: "Personne",
        avatar: null,
        __typename: "CurrentActor",
      }),
    },
  };

  const mockClient = createMockClient({
    cache,
    resolvers: defaultResolvers,
  });

  mockClient.setRequestHandler(
    PERSON_GROUP_MEMBERSHIPS,
    () =>
      new Promise((resolve) =>
        resolve({
          data: {
            person: { id: "5", memberships: { total: 0, elements: [] } },
          },
        })
      )
  );

  mockClient.setRequestHandler(
    IDENTITIES,
    () =>
      new Promise((resolve) =>
        resolve({
          data: {
            loggedUser: {
              actors: [{ id: "9", preferredUsername: "sam", name: "Samuel" }],
            },
          },
        })
      )
  );

  app.provide(DefaultApolloClient, mockClient);
  app.use(
    createRouter({
      history: createMemoryHistory(),
      routes: [{ path: "/", name: "home", component: { render: () => null } }],
    })
  );
}
</script>
