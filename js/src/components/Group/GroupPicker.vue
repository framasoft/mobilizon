<template>
  <div class="modal-card">
    <header class="modal-card-head">
      <p class="modal-card-title">{{ $t("Pick a group") }}</p>
    </header>
    <section class="modal-card-body">
      <div class="list is-hoverable">
        <a
          class="list-item"
          v-for="groupMembership in actualMemberships"
          :class="{
            'is-active': groupMembership.parent.id === currentGroup.id,
          }"
          @click="changeCurrentGroup(groupMembership.parent)"
          :key="groupMembership.id"
        >
          <div class="media">
            <img
              class="media-left image is-48x48"
              v-if="groupMembership.parent.avatar"
              :src="groupMembership.parent.avatar.url"
              alt=""
            />
            <b-icon
              class="media-left"
              v-else
              size="is-large"
              icon="account-circle"
            />
            <div class="media-content">
              <h3>@{{ groupMembership.parent.name }}</h3>
              <small>{{
                `@${groupMembership.parent.preferredUsername}`
              }}</small>
            </div>
          </div>
        </a>
        <a
          class="list-item"
          @click="changeCurrentGroup(new Group())"
          v-if="currentGroup.id"
        >
          <h3>{{ $t("Unset group") }}</h3>
        </a>
      </div>
    </section>
    <slot name="footer" />
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IGroup, IPerson, Group } from "@/types/actor";
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
export default class GroupPicker extends Vue {
  @Prop() value!: IGroup;

  @Prop() identity!: IPerson;

  @Prop({ required: false, default: false }) restrictModeratorLevel!: boolean;

  groupMemberships: Paginate<IMember> = { elements: [], total: 0 };

  currentGroup: IGroup = this.value;

  Group = Group;

  changeCurrentGroup(group: IGroup): void {
    this.currentGroup = group;
    this.$emit("input", group);
  }

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
}
</script>
