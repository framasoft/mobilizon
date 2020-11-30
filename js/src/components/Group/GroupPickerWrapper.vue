<template>
  <div class="group-picker">
    <div
      class="no-group box"
      v-if="!currentGroup.id && groupMemberships.total > 0"
      @click="isComponentModalActive = true"
    >
      <p class="is-4">{{ $t("Add a group") }}</p>
      <p class="is-6 is-size-6 has-text-grey">
        {{ $t("The event will show the group as organizer.") }}
      </p>
    </div>
    <div
      v-if="inline && currentGroup.id"
      class="inline box"
      @click="isComponentModalActive = true"
    >
      <div class="media">
        <div class="media-left">
          <figure class="image is-48x48" v-if="currentGroup.avatar">
            <img
              class="image is-rounded"
              :src="currentGroup.avatar.url"
              :alt="currentGroup.avatar.alt"
            />
          </figure>
          <b-icon v-else size="is-large" icon="account-circle" />
        </div>
        <div class="media-content" v-if="currentGroup.name">
          <p class="is-4">{{ currentGroup.name }}</p>
          <p class="is-6 has-text-grey">
            {{ `@${currentGroup.preferredUsername}` }}
          </p>
        </div>
        <div class="media-content" v-else>
          {{ `@${currentGroup.preferredUsername}` }}
        </div>
        <b-button type="is-text" @click="isComponentModalActive = true">
          {{ $t("Change") }}
        </b-button>
      </div>
    </div>
    <span
      v-else-if="currentGroup.id"
      class="block"
      @click="isComponentModalActive = true"
    >
      <img
        class="image is-48x48"
        v-if="currentGroup.avatar"
        :src="currentGroup.avatar.url"
        :alt="currentGroup.avatar.alt"
      />
      <b-icon v-else size="is-large" icon="account-circle" />
    </span>
    <div v-if="groupMemberships.total === 0" class="box">
      <p class="is-4">
        {{ $t("This identity is not a member of any group.") }}
      </p>
      <p class="is-6 is-size-6 has-text-grey">
        {{ $t("You need to create the group before you create an event.") }}
      </p>
    </div>
    <b-modal :active.sync="isComponentModalActive" has-modal-card>
      <group-picker
        v-model="currentGroup"
        :identity.sync="identity"
        @input="relay"
        :restrict-moderator-level="true"
      />
    </b-modal>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import { IMember } from "@/types/actor/member.model";
import { IGroup, IPerson } from "../../types/actor";
import GroupPicker from "./GroupPicker.vue";
import { PERSON_MEMBERSHIPS } from "../../graphql/actor";
import { Paginate } from "../../types/paginate";

@Component({
  components: { GroupPicker },
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
export default class GroupPickerWrapper extends Vue {
  @Prop({ type: Object, required: true }) value!: IGroup;

  @Prop({ default: true, type: Boolean }) inline!: boolean;

  @Prop({ type: Object, required: true }) identity!: IPerson;

  isComponentModalActive = false;

  currentGroup: IGroup = this.value;

  groupMemberships: Paginate<IMember> = { elements: [], total: 0 };

  @Watch("value")
  updateCurrentGroup(value: IGroup): void {
    this.currentGroup = value;
  }

  relay(group: IGroup): void {
    this.currentGroup = group;
    this.$emit("input", group);
    this.isComponentModalActive = false;
  }
}
</script>
<style lang="scss" scoped>
.group-picker {
  .block,
  .no-group,
  .inline {
    cursor: pointer;
  }
}
</style>
