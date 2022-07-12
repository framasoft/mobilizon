<template>
  <div class="list is-hoverable">
    <o-input
      dir="auto"
      :placeholder="$t('Filter by profile or group name')"
      v-model="actorFilter"
    />
    <transition-group
      tag="ul"
      class="grid grid-cols-1 gap-y-3 m-5 max-w-md mx-auto"
      enter-active-class="duration-300 ease-out"
      enter-from-class="transform opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="duration-200 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="transform opacity-0"
    >
      <li
        class="relative focus-within:shadow-lg"
        v-for="availableActor in actualFilteredAvailableActors"
        :key="availableActor?.id"
      >
        <input
          class="sr-only peer"
          type="radio"
          :value="availableActor"
          name="availableActors"
          v-model="selectedActor"
          :id="`availableActor-${availableActor?.id}`"
        />
        <label
          class="flex flex-wrap p-3 bg-white hover:bg-gray-50 dark:bg-violet-3 dark:hover:bg-violet-3/60 border border-gray-300 rounded-lg cursor-pointer peer-checked:ring-primary peer-checked:ring-2 peer-checked:border-transparent"
          :for="`availableActor-${availableActor?.id}`"
        >
          <figure class="" v-if="availableActor?.avatar">
            <img
              class="rounded"
              :src="availableActor.avatar.url"
              alt=""
              width="48"
              height="48"
            />
          </figure>
          <AccountCircle v-else :size="48" />
          <div class="flex-1">
            <h3>{{ availableActor?.name }}</h3>
            <small>{{ `@${availableActor?.preferredUsername}` }}</small>
          </div>
        </label>
      </li>
    </transition-group>
  </div>
</template>
<script lang="ts" setup>
import { IActor } from "@/types/actor";
import { LOGGED_USER_MEMBERSHIPS } from "@/graphql/actor";
import { IMember } from "@/types/actor/member.model";
import { MemberRole } from "@/types/enums";
import { computed, ref } from "vue";
import {
  useCurrentActorClient,
  useCurrentUserIdentities,
} from "@/composition/apollo/actor";
import { IUser } from "@/types/current-user.model";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import { useQuery } from "@vue/apollo-composable";

const props = withDefaults(
  defineProps<{ modelValue: IActor; restrictModeratorLevel?: boolean }>(),
  { restrictModeratorLevel: false }
);

const emit = defineEmits(["update:modelValue"]);

const { currentActor } = useCurrentActorClient();
const { identities } = useCurrentUserIdentities();

const actorFilter = ref("");

const { result: groupMembershipsResult } = useQuery<{
  loggedUser: Pick<IUser, "memberships">;
}>(LOGGED_USER_MEMBERSHIPS, () => ({
  page: 1,
  limit: 10,
  membershipName: actorFilter.value,
}));
const groupMemberships = computed(
  () =>
    groupMembershipsResult.value?.loggedUser.memberships ?? {
      elements: [],
      total: 0,
    }
);

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

  set(actor: IActor | undefined) {
    emit("update:modelValue", actor);
  },
});

const actualMemberships = computed((): IMember[] => {
  if (props.restrictModeratorLevel) {
    return groupMemberships.value.elements.filter((membership: IMember) =>
      [
        MemberRole.ADMINISTRATOR,
        MemberRole.MODERATOR,
        MemberRole.CREATOR,
      ].includes(membership.role)
    );
  }
  return groupMemberships.value.elements;
});

const actualAvailableActors = computed((): (IActor | undefined)[] => {
  return [
    currentActor.value,
    ...(identities.value ?? []).filter(
      (identity: IActor) => identity.id !== currentActor.value?.id
    ),
    ...actualMemberships.value.map((member) => member.parent),
  ].filter((elem) => elem);
});

const actualFilteredAvailableActors = computed((): (IActor | undefined)[] => {
  return (actualAvailableActors.value ?? []).filter((actor) => {
    if (actor === undefined) return false;
    return [
      actor.preferredUsername.toLowerCase(),
      actor.name?.toLowerCase(),
      actor.domain?.toLowerCase(),
    ].some((match) => match?.includes(actorFilter.value.toLowerCase()));
  });
});
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
:deep(.list-item) {
  box-sizing: content-box;

  label.b-radio {
    padding: 0.85rem 0;

    .media {
      padding: 0.25rem 0;
      align-items: center;

      // figure.image,
      // span.icon.media-left {
      //   @include margin-right(0.5rem);
      // }

      // span.icon.media-left {
      //   @include margin-left(-0.25rem);
      // }
    }
  }
}
</style>
