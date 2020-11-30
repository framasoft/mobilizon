<template>
  <div class="list is-hoverable">
    <b-radio-button
      v-model="currentActor"
      :native-value="availableActor"
      class="list-item"
      v-for="availableActor in actualAvailableActors"
      :class="{ 'is-active': availableActor.id === currentActor.id }"
      :key="availableActor.id"
    >
      <div class="media">
        <figure class="image is-48x48" v-if="availableActor.avatar">
          <img
            class="media-left is-rounded"
            :src="availableActor.avatar.url"
            alt=""
          />
        </figure>
        <b-icon
          class="media-left"
          v-else
          size="is-large"
          icon="account-circle"
        />
        <div class="media-content">
          <h3>{{ availableActor.name }}</h3>
          <small>{{ `@${availableActor.preferredUsername}` }}</small>
        </div>
      </div>
    </b-radio-button>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import { IPerson, IActor, Actor } from "@/types/actor";
import { PERSON_MEMBERSHIPS } from "@/graphql/actor";
import { Paginate } from "@/types/paginate";
import { IMember } from "@/types/actor/member.model";
import { MemberRole } from "@/types/enums";

@Component({
  apollo: {
    groupMemberships: {
      query: PERSON_MEMBERSHIPS,
      variables() {
        return {
          id: this.identity.id,
        };
      },
      update: (data) => data.person.memberships,
      skip() {
        return !this.identity.id;
      },
    },
  },
})
export default class OrganizerPicker extends Vue {
  @Prop() value!: IActor;

  @Prop() identity!: IPerson;

  @Prop({ required: false, default: false }) restrictModeratorLevel!: boolean;

  groupMemberships: Paginate<IMember> = { elements: [], total: 0 };

  currentActor: IActor = this.value;

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
      this.identity,
      ...this.actualMemberships.map((member) => member.parent),
    ];
  }

  @Watch("currentActor")
  async fetchMembersForGroup(): Promise<void> {
    this.$emit("input", this.currentActor);
  }
}
</script>
<style lang="scss" scoped>
::v-deep .list-item {
  box-sizing: content-box;

  label.b-radio {
    padding: 0.85rem 0;

    .media {
      padding: 0.25rem 0;
      align-items: center;

      figure.image,
      span.icon.media-left {
        margin-right: 0.5rem;
      }

      span.icon.media-left {
        margin-left: -0.25rem;
      }
    }
  }
}
</style>
