<template>
  <div
    class="bg-white border border-gray-300 rounded-lg cursor-pointer"
    v-if="selectedActor"
  >
    <!-- If we have a current actor (inline) -->
    <div
      v-if="inline && selectedActor.id"
      class="inline box"
      dir="auto"
      @click="isComponentModalActive = true"
    >
      <div class="media">
        <div class="media-left">
          <figure class="image is-48x48" v-if="selectedActor.avatar">
            <img
              class="image is-rounded"
              :src="selectedActor.avatar.url"
              :alt="selectedActor.avatar.alt || ''"
            />
          </figure>
          <b-icon v-else size="is-large" icon="account-circle" />
        </div>
        <div class="media-content" v-if="selectedActor.name">
          <p class="is-4">{{ selectedActor.name }}</p>
          <p class="is-6 has-text-grey-dark">
            {{ `@${selectedActor.preferredUsername}` }}
          </p>
        </div>
        <div class="media-content" v-else>
          {{ `@${selectedActor.preferredUsername}` }}
        </div>
        <b-button type="is-text" @click="isComponentModalActive = true">
          {{ $t("Change") }}
        </b-button>
      </div>
    </div>
    <!-- If we have a current actor -->
    <span
      v-else-if="selectedActor.id"
      class="block"
      @click="isComponentModalActive = true"
    >
      <img
        class="image is-48x48"
        v-if="selectedActor.avatar"
        :src="selectedActor.avatar.url"
        :alt="selectedActor.avatar.alt"
      />
      <b-icon v-else size="is-large" icon="account-circle" />
    </span>
    <b-modal
      :active.sync="isComponentModalActive"
      has-modal-card
      :close-button-aria-label="$t('Close')"
    >
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">{{ $t("Pick a profile or a group") }}</p>
        </header>
        <section class="modal-card-body">
          <div class="columns">
            <div class="column actor-picker">
              <organizer-picker
                v-model="selectedActor"
                @input="relay"
                :restrict-moderator-level="true"
              />
            </div>
            <div class="column contact-picker">
              <div v-if="isSelectedActorAGroup">
                <p>{{ $t("Add a contact") }}</p>
                <b-input
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
                    <b-checkbox
                      v-model="actualContacts"
                      :native-value="actor.id"
                    >
                      <div class="media">
                        <div class="media-left">
                          <figure class="image is-48x48" v-if="actor.avatar">
                            <img
                              class="image is-rounded"
                              :src="actor.avatar.url"
                              :alt="actor.avatar.alt"
                            />
                          </figure>
                          <b-icon
                            v-else
                            size="is-large"
                            icon="account-circle"
                          />
                        </div>
                        <div class="media-content" v-if="actor.name">
                          <p class="is-4">{{ actor.name }}</p>
                          <p class="is-6 has-text-grey-dark">
                            {{ `@${usernameWithDomain(actor)}` }}
                          </p>
                        </div>
                        <div class="media-content" v-else>
                          {{ `@${usernameWithDomain(actor)}` }}
                        </div>
                      </div>
                    </b-checkbox>
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
              <div v-else class="content has-text-grey-dark has-text-centered">
                <p>{{ $t("Your profile will be shown as contact.") }}</p>
              </div>
            </div>
          </div>
        </section>
        <footer class="modal-card-foot">
          <button class="button is-primary" type="button" @click="pickActor">
            {{ $t("Pick") }}
          </button>
        </footer>
      </div>
    </b-modal>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import { IMember } from "@/types/actor/member.model";
import { IActor, IGroup, IPerson, usernameWithDomain } from "../../types/actor";
import OrganizerPicker from "./OrganizerPicker.vue";
import EmptyContent from "../Utils/EmptyContent.vue";
import {
  CURRENT_ACTOR_CLIENT,
  IDENTITIES,
  PERSON_GROUP_MEMBERSHIPS,
} from "../../graphql/actor";
import { Paginate } from "../../types/paginate";
import { GROUP_MEMBERS } from "@/graphql/member";
import { ActorType, MemberRole } from "@/types/enums";
import debounce from "lodash/debounce";

const MEMBER_ROLES = [
  MemberRole.CREATOR,
  MemberRole.ADMINISTRATOR,
  MemberRole.MODERATOR,
  MemberRole.MEMBER,
];

@Component({
  components: { OrganizerPicker, EmptyContent },
  apollo: {
    members: {
      query: GROUP_MEMBERS,
      variables() {
        return {
          groupName: usernameWithDomain(this.selectedActor),
          page: this.membersPage,
          limit: 10,
          roles: MEMBER_ROLES.join(","),
          name: this.contactFilter,
        };
      },
      update: (data) => data.group.members,
      skip() {
        return (
          !this.selectedActor || this.selectedActor.type !== ActorType.GROUP
        );
      },
    },
    currentActor: CURRENT_ACTOR_CLIENT,
    personMemberships: {
      query: PERSON_GROUP_MEMBERSHIPS,
      variables() {
        return {
          id: this.currentActor?.id,
          page: 1,
          limit: 10,
          groupId: this.$route.query?.actorId,
        };
      },
      update: (data) => data.person.memberships,
    },
    identities: IDENTITIES,
  },
})
export default class OrganizerPickerWrapper extends Vue {
  @Prop({ type: Object, required: false }) value!: IActor;

  @Prop({ default: true, type: Boolean }) inline!: boolean;

  @Prop({ type: Array, required: false, default: () => [] })
  contacts!: IActor[];

  currentActor!: IPerson;

  identities!: IPerson[];

  isComponentModalActive = false;

  contactFilter = "";

  usernameWithDomain = usernameWithDomain;

  members: Paginate<IMember> = { elements: [], total: 0 };

  membersPage = 1;

  personMemberships: Paginate<IMember> = { elements: [], total: 0 };

  data(): Record<string, unknown> {
    return {
      debounceSetFilterByName: debounce(this.setContactFilter, 1000),
    };
  }

  get actualContacts(): (string | undefined)[] {
    return this.contacts.map(({ id }) => id);
  }

  set actualContacts(contactsIds: (string | undefined)[]) {
    this.$emit(
      "update:contacts",
      this.actorMembers.filter(({ id }) => contactsIds.includes(id))
    );
  }

  setContactFilter(contactFilter: string) {
    this.contactFilter = contactFilter;
  }

  @Watch("personMemberships")
  setInitialActor(): void {
    if (
      this.personMemberships?.elements[0]?.parent?.id ===
      this.$route.query?.actorId
    ) {
      this.selectedActor = this.personMemberships?.elements[0]?.parent;
    }
  }

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

  set selectedActor(selectedActor: IActor | undefined) {
    this.$emit("input", selectedActor);
  }

  async relay(group: IGroup): Promise<void> {
    this.actualContacts = [];
    this.selectedActor = group;
  }

  pickActor(): void {
    this.isComponentModalActive = false;
  }

  get actorMembers(): IActor[] {
    if (this.isSelectedActorAGroup) {
      return this.members.elements.map(({ actor }: { actor: IActor }) => actor);
    }
    return [];
  }

  get filteredActorMembers(): IActor[] {
    return this.actorMembers.filter((actor) => {
      return [
        actor.preferredUsername.toLowerCase(),
        actor.name?.toLowerCase(),
        actor.domain?.toLowerCase(),
      ];
    });
  }

  get isSelectedActorAGroup(): boolean {
    return this.selectedActor?.type === ActorType.GROUP;
  }
}
</script>
<style lang="scss" scoped>
.modal-card-body .columns .column {
  &.actor-picker,
  &.contact-picker {
    overflow-y: auto;
    max-height: 400px;
  }
}
</style>
