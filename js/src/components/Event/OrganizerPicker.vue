<template>
  <div class="list is-hoverable">
    <b-input
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
        :key="availableActor.id"
      >
        <input
          class="sr-only peer"
          type="radio"
          :value="availableActor"
          name="availableActors"
          v-model="selectedActor"
          :id="`availableActor-${availableActor.id}`"
        />
        <label
          class="flex flex-wrap p-3 bg-white border border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50 peer-checked:ring-primary peer-checked:ring-2 peer-checked:border-transparent"
          :for="`availableActor-${availableActor.id}`"
        >
          <figure class="image is-48x48" v-if="availableActor.avatar">
            <img
              class="image is-rounded"
              :src="availableActor.avatar.url"
              alt=""
            />
          </figure>
          <b-icon v-else size="is-large" icon="account-circle" />
          <div>
            <h3>{{ availableActor.name }}</h3>
            <small>{{ `@${availableActor.preferredUsername}` }}</small>
          </div>
        </label>
      </li>
    </transition-group>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IPerson, IActor, Actor } from "@/types/actor";
import {
  CURRENT_ACTOR_CLIENT,
  IDENTITIES,
  LOGGED_USER_MEMBERSHIPS,
} from "@/graphql/actor";
import { Paginate } from "@/types/paginate";
import { IMember } from "@/types/actor/member.model";
import { MemberRole } from "@/types/enums";

@Component({
  apollo: {
    groupMemberships: {
      query: LOGGED_USER_MEMBERSHIPS,
      update: (data) => data.loggedUser.memberships,
      variables() {
        return {
          page: 1,
          limit: 10,
          membershipName: this.actorFilter,
        };
      },
    },
    identities: IDENTITIES,
    currentActor: CURRENT_ACTOR_CLIENT,
  },
})
export default class OrganizerPicker extends Vue {
  @Prop() value!: IActor;

  @Prop({ required: false, default: false }) restrictModeratorLevel!: boolean;

  groupMemberships: Paginate<IMember> = { elements: [], total: 0 };

  currentActor!: IPerson;

  actorFilter = "";

  get selectedActor(): IActor | undefined {
    if (this.value?.id) {
      return this.value;
    }
    if (this.currentActor) {
      return this.identities.find(
        (identity) => identity.id === this.currentActor.id
      );
    }
    return undefined;
  }

  set selectedActor(actor: IActor | undefined) {
    this.$emit("input", actor);
  }

  identities: IActor[] = [];

  Actor = Actor;

  get actualMemberships(): IMember[] {
    if (this.restrictModeratorLevel) {
      return this.groupMemberships.elements.filter((membership: IMember) =>
        [
          MemberRole.ADMINISTRATOR,
          MemberRole.MODERATOR,
          MemberRole.CREATOR,
        ].includes(membership.role)
      );
    }
    return this.groupMemberships.elements;
  }

  get actualAvailableActors(): IActor[] {
    return [
      this.currentActor,
      ...this.identities.filter(
        (identity: IActor) => identity.id !== this.currentActor?.id
      ),
      ...this.actualMemberships.map((member) => member.parent),
    ].filter((elem) => elem);
  }

  get actualFilteredAvailableActors(): IActor[] {
    return this.actualAvailableActors.filter((actor) => {
      return [
        actor.preferredUsername.toLowerCase(),
        actor.name?.toLowerCase(),
        actor.domain?.toLowerCase(),
      ].some((match) => match?.includes(this.actorFilter.toLowerCase()));
    });
  }
}
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
::v-deep .list-item {
  box-sizing: content-box;

  label.b-radio {
    padding: 0.85rem 0;

    .media {
      padding: 0.25rem 0;
      align-items: center;

      figure.image,
      span.icon.media-left {
        @include margin-right(0.5rem);
      }

      span.icon.media-left {
        @include margin-left(-0.25rem);
      }
    }
  }
}
</style>
