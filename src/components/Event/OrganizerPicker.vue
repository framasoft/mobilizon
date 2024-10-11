<template>
  <div class="max-w-md mx-auto">
    <o-input
      expanded
      dir="auto"
      :placeholder="t('Filter by profile or group name')"
      v-model="actorFilterProxy"
      class=""
    />
    <transition-group
      tag="ul"
      class="grid grid-cols-1 gap-y-3 m-5 max-w-md mx-auto"
      :class="{ hidden: actualFilteredAvailableActors.length === 0 }"
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
          class="flex items-center gap-2 p-3 bg-white hover:bg-gray-50 dark:bg-violet-3 dark:hover:bg-violet-3/60 border border-gray-300 rounded-lg cursor-pointer peer-checked:ring-primary peer-checked:ring-2 peer-checked:border-transparent"
          :for="`availableActor-${availableActor?.id}`"
        >
          <figure class="h-12 w-12" v-if="availableActor?.avatar">
            <img
              class="rounded-full h-full w-full object-cover"
              :src="availableActor.avatar.url"
              alt=""
              width="48"
              height="48"
            />
          </figure>
          <AccountCircle v-else :size="48" />
          <div class="flex-1 w-px">
            <h3 class="line-clamp-2">{{ availableActor?.name }}</h3>
            <small class="flex truncate">{{
              `@${availableActor?.preferredUsername}`
            }}</small>
          </div>
        </label>
      </li>
    </transition-group>
  </div>
</template>
<script lang="ts" setup>
import { IActor, IPerson } from "@/types/actor";
import { IMember } from "@/types/actor/member.model";
import { MemberRole } from "@/types/enums";
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";

const props = withDefaults(
  defineProps<{
    currentActor: IPerson;
    modelValue: IActor;
    restrictModeratorLevel?: boolean;
    identities: IActor[];
    actorFilter: string;
    groupMemberships: IMember[];
  }>(),
  { restrictModeratorLevel: false }
);

const emit = defineEmits(["update:modelValue", "update:actorFilter"]);

const { t } = useI18n({ useScope: "global" });

const selectedActor = computed({
  get(): IActor | undefined {
    if (props.modelValue?.id) {
      return props.modelValue;
    }
    if (props.currentActor) {
      return props.identities.find(
        (identity) => identity.id === props.currentActor?.id
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
    return props.groupMemberships.filter((membership: IMember) =>
      [
        MemberRole.ADMINISTRATOR,
        MemberRole.MODERATOR,
        MemberRole.CREATOR,
      ].includes(membership.role)
    );
  }
  return props.groupMemberships;
});

const actualAvailableActors = computed((): (IActor | undefined)[] => {
  return [
    props.currentActor,
    ...props.identities.filter(
      (identity: IActor) => identity.id !== props.currentActor?.id
    ),
    ...actualMemberships.value.map((member) => member.parent),
  ].filter((elem) => elem);
});

const actualFilteredAvailableActors = computed((): (IActor | undefined)[] => {
  return (actualAvailableActors.value ?? []).filter((actor) => {
    if (actor === undefined) return false;
    return [
      actor.preferredUsername?.toLowerCase(),
      actor.name?.toLowerCase(),
      actor.domain?.toLowerCase(),
    ].some((match) => match?.includes(actorFilterProxy.value.toLowerCase()));
  });
});

const actorFilterProxy = computed({
  get() {
    return props.actorFilter;
  },
  set(newActorFilter: string) {
    emit("update:actorFilter", newActorFilter);
  },
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
