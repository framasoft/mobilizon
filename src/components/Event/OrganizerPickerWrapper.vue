<template>
  <div
    class="bg-white dark:bg-violet-3 border border-gray-300 rounded-lg cursor-pointer"
    v-if="selectedActor"
  >
    <!-- If we have a current actor (inline) -->
    <div
      v-if="inline && selectedActor.id"
      class=""
      dir="auto"
      @click="isComponentModalActive = true"
    >
      <div class="flex gap-1 p-4">
        <div class="">
          <figure class="h-12 w-12" v-if="selectedActor.avatar">
            <img
              class="rounded-full h-full w-full object-cover"
              :src="selectedActor.avatar.url"
              :alt="selectedActor.avatar.alt ?? ''"
              height="48"
              width="48"
            />
          </figure>
          <AccountCircle v-else :size="48" />
        </div>
        <div class="flex-1" v-if="selectedActor.name">
          <p class="">{{ selectedActor.name }}</p>
          <p class="">
            {{ `@${selectedActor.preferredUsername}` }}
          </p>
        </div>
        <div class="flex-1" v-else>
          {{ `@${selectedActor.preferredUsername}` }}
        </div>
        <o-button @click="isComponentModalActive = true">
          {{ $t("Change") }}
        </o-button>
      </div>
    </div>
    <!-- If we have a current actor -->
    <span
      v-else-if="selectedActor.id"
      class="block"
      @click="isComponentModalActive = true"
    >
      <img
        class="rounded"
        v-if="selectedActor.avatar"
        :src="selectedActor.avatar.url"
        :alt="selectedActor.avatar.alt"
        width="48"
        height="48"
      />
      <AccountCircle v-else :size="48" />
    </span>
    <o-modal
      v-model:active="isComponentModalActive"
      has-modal-card
      :close-button-aria-label="$t('Close')"
    >
      <div class="p-2 rounded">
        <header class="">
          <h2 class="">{{ $t("Pick a profile or a group") }}</h2>
        </header>
        <section class="">
          <div class="flex flex-wrap gap-2 items-center flex-col lg:flex-row">
            <div class="max-h-[400px] overflow-y-auto flex-1 w-full">
              <organizer-picker
                class="p-5 w-3/4"
                v-if="currentActor"
                :current-actor="currentActor"
                :identities="identities ?? []"
                v-model="selectedActor"
                @update:model-value="relay"
                :restrict-moderator-level="true"
                :group-memberships="groupMemberships"
                v-model:actorFilter="actorFilter"
              />
            </div>
            <div class="pl-2 max-h-[400px] overflow-y-auto">
              <div v-if="isSelectedActorAGroup">
                <p>{{ $t("Add a contact") }}</p>
                <o-input
                  expanded
                  :placeholder="$t('Filter by name')"
                  :value="contactFilter"
                  @input="debounceSetFilterByName"
                  dir="auto"
                />
                <div v-if="actorMembers.length > 0">
                  <p
                    class="field"
                    v-for="actor in filteredActorMembers"
                    :key="actor.id"
                  >
                    <o-checkbox
                      v-model="actualContacts"
                      :native-value="actor.id"
                    >
                      <div class="flex gap-1">
                        <div class="">
                          <figure class="" v-if="actor.avatar">
                            <img
                              class="rounded"
                              :src="actor.avatar.url"
                              :alt="actor.avatar.alt"
                              width="48"
                              height="48"
                            />
                          </figure>
                          <AccountCircle v-else :size="48" />
                        </div>
                        <div class="" v-if="actor.name">
                          <p class="">{{ actor.name }}</p>
                          <p class="">
                            {{ `@${usernameWithDomain(actor)}` }}
                          </p>
                        </div>
                        <div class="" v-else>
                          {{ `@${usernameWithDomain(actor)}` }}
                        </div>
                      </div>
                    </o-checkbox>
                  </p>
                </div>
                <div
                  v-else-if="
                    actorMembers.length === 0 && contactFilter.length > 0
                  "
                >
                  <empty-content icon="account-multiple" :inline="true">
                    {{ $t("No group member found") }}
                  </empty-content>
                </div>
              </div>
              <div v-else class="">
                <p>{{ $t("Your profile will be shown as contact.") }}</p>
              </div>
            </div>
          </div>
        </section>
        <footer class="my-2 text-center sm:text-right">
          <o-button
            variant="primary"
            class="w-full sm:w-auto"
            @click="pickActor"
          >
            {{ $t("Pick") }}
          </o-button>
        </footer>
      </div>
    </o-modal>
  </div>
</template>
<script lang="ts" setup>
import { IActor, IGroup, usernameWithDomain } from "../../types/actor";
import OrganizerPicker from "./OrganizerPicker.vue";
import EmptyContent from "../Utils/EmptyContent.vue";
import {
  LOGGED_USER_MEMBERSHIPS,
  PERSON_GROUP_MEMBERSHIPS,
} from "../../graphql/actor";
import { GROUP_MEMBERS } from "@/graphql/member";
import { ActorType, MemberRole } from "@/types/enums";
import { useQuery } from "@vue/apollo-composable";
import { computed, ref, watch } from "vue";
import {
  useCurrentActorClient,
  useCurrentUserIdentities,
} from "@/composition/apollo/actor";
import { useRoute } from "vue-router";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import debounce from "lodash/debounce";
import { IUser } from "@/types/current-user.model";
import { IMember } from "@/types/actor/member.model";
import { Paginate } from "@/types/paginate";

const MEMBER_ROLES = [
  MemberRole.CREATOR,
  MemberRole.ADMINISTRATOR,
  MemberRole.MODERATOR,
  MemberRole.MEMBER,
];

const { currentActor } = useCurrentActorClient();

const route = useRoute();

const { result: personMembershipsResult } = useQuery(
  PERSON_GROUP_MEMBERSHIPS,
  () => ({
    id: currentActor.value?.id,
    page: 1,
    limit: 10,
    groupId: route.query?.actorId,
  }),
  () => ({
    enabled: currentActor.value?.id !== undefined,
  })
);

const personMemberships = computed(
  () =>
    personMembershipsResult.value?.person.memberships ?? {
      elements: [],
      total: 0,
    }
);

const { identities } = useCurrentUserIdentities();

const props = withDefaults(
  defineProps<{
    modelValue?: IActor;
    inline?: boolean;
    contacts?: IActor[];
  }>(),
  { inline: true, contacts: () => [] }
);

const emit = defineEmits(["update:modelValue", "update:contacts"]);

const selectedActor = computed({
  get(): IActor | undefined {
    if (props.modelValue?.id) {
      return props.modelValue;
    }
    if (currentActor.value) {
      return (identities.value ?? []).find(
        (identity) => identity.id === currentActor.value?.id
      );
    }
    return undefined;
  },
  set(newSelectedActor: IActor | undefined) {
    emit("update:modelValue", newSelectedActor);
  },
});

const isComponentModalActive = ref(false);
const contactFilter = ref("");
const membersPage = ref(1);

const { result: membersResult } = useQuery<{ group: Pick<IGroup, "members"> }>(
  GROUP_MEMBERS,
  () => ({
    groupName: usernameWithDomain(selectedActor.value),
    page: membersPage.value,
    limit: 10,
    roles: MEMBER_ROLES.join(","),
    name: contactFilter.value,
  }),
  () => ({ enabled: selectedActor.value?.type === ActorType.GROUP })
);

const members = computed<Paginate<IMember>>(() =>
  selectedActor.value?.type === ActorType.GROUP
    ? membersResult.value?.group?.members ?? { elements: [], total: 0 }
    : { elements: [], total: 0 }
);

const actualContacts = computed({
  get(): (string | undefined)[] {
    return props.contacts.map(({ id }) => id);
  },
  set(contactsIds: (string | undefined)[]) {
    emit(
      "update:contacts",
      actorMembers.value.filter(({ id }) => contactsIds.includes(id))
    );
  },
});

const setContactFilter = (newContactFilter: string) => {
  contactFilter.value = newContactFilter;
};

const debounceSetFilterByName = debounce(setContactFilter, 1000);

watch(personMemberships, () => {
  if (
    personMemberships.value?.elements[0]?.parent?.id === route.query?.actorId
  ) {
    selectedActor.value = personMemberships.value?.elements[0]?.parent;
  }
});

const relay = async (group: IGroup): Promise<void> => {
  actualContacts.value = [];
  selectedActor.value = group;
};

const pickActor = (): void => {
  isComponentModalActive.value = false;
};

const actorMembers = computed((): IActor[] => {
  if (isSelectedActorAGroup.value) {
    return members.value.elements.map(({ actor }: { actor: IActor }) => actor);
  }
  return [];
});

const filteredActorMembers = computed((): IActor[] => {
  return actorMembers.value.filter((actor) => {
    return [
      actor.preferredUsername.toLowerCase(),
      actor.name?.toLowerCase(),
      actor.domain?.toLowerCase(),
    ];
  });
});

const isSelectedActorAGroup = computed((): boolean => {
  return selectedActor.value?.type === ActorType.GROUP;
});

const actorFilter = ref("");

const { result: groupMembershipsResult } = useQuery<{
  loggedUser: Pick<IUser, "memberships">;
}>(LOGGED_USER_MEMBERSHIPS, () => ({
  page: 1,
  limit: 10,
  membershipName: actorFilter.value,
}));
const groupMemberships = computed(
  () => groupMembershipsResult.value?.loggedUser.memberships.elements ?? []
);
</script>
