<template>
  <div class="organizer-picker">
    <!-- If we have a current actor (inline) -->
    <div
      v-if="inline && currentActor.id"
      class="inline box"
      @click="isComponentModalActive = true"
    >
      <div class="media">
        <div class="media-left">
          <figure class="image is-48x48" v-if="currentActor.avatar">
            <img
              class="image is-rounded"
              :src="currentActor.avatar.url"
              :alt="currentActor.avatar.alt"
            />
          </figure>
          <b-icon v-else size="is-large" icon="account-circle" />
        </div>
        <div class="media-content" v-if="currentActor.name">
          <p class="is-4">{{ currentActor.name }}</p>
          <p class="is-6 has-text-grey">
            {{ `@${currentActor.preferredUsername}` }}
          </p>
        </div>
        <div class="media-content" v-else>
          {{ `@${currentActor.preferredUsername}` }}
        </div>
        <b-button type="is-text" @click="isComponentModalActive = true">
          {{ $t("Change") }}
        </b-button>
      </div>
    </div>
    <!-- If we have a current actor -->
    <span
      v-else-if="currentActor.id"
      class="block"
      @click="isComponentModalActive = true"
    >
      <img
        class="image is-48x48"
        v-if="currentActor.avatar"
        :src="currentActor.avatar.url"
        :alt="currentActor.avatar.alt"
      />
      <b-icon v-else size="is-large" icon="account-circle" />
    </span>
    <!-- If we have no current actor -->
    <div v-if="groupMemberships.total === 0 || !currentActor.id" class="box">
      <div class="media">
        <div class="media-left">
          <figure class="image is-48x48" v-if="identity.avatar">
            <img
              class="image is-rounded"
              :src="identity.avatar.url"
              :alt="identity.avatar.alt"
            />
          </figure>
          <b-icon v-else size="is-large" icon="account-circle" />
        </div>
        <div class="media-content" v-if="identity.name">
          <p class="is-4">{{ identity.name }}</p>
          <p class="is-6 has-text-grey">
            {{ `@${identity.preferredUsername}` }}
          </p>
        </div>
        <div class="media-content" v-else>
          {{ `@${identity.preferredUsername}` }}
        </div>
        <b-button type="is-text" @click="isComponentModalActive = true">
          {{ $t("Change") }}
        </b-button>
      </div>
    </div>
    <b-modal :active.sync="isComponentModalActive" has-modal-card>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">{{ $t("Pick a profile or a group") }}</p>
        </header>
        <section class="modal-card-body">
          <div class="columns">
            <div class="column">
              <organizer-picker
                v-model="currentActor"
                :identity.sync="identity"
                @input="relay"
                :restrict-moderator-level="true"
              />
            </div>
            <div class="column">
              <div v-if="actorMembersForCurrentActor.length > 0">
                <p>{{ $t("Add a contact") }}</p>
                <p
                  class="field"
                  v-for="actor in actorMembersForCurrentActor"
                  :key="actor.id"
                >
                  <b-checkbox v-model="actualContacts" :native-value="actor.id">
                    <div class="media">
                      <div class="media-left">
                        <figure class="image is-48x48" v-if="actor.avatar">
                          <img
                            class="image is-rounded"
                            :src="actor.avatar.url"
                            :alt="actor.avatar.alt"
                          />
                        </figure>
                        <b-icon v-else size="is-large" icon="account-circle" />
                      </div>
                      <div class="media-content" v-if="actor.name">
                        <p class="is-4">{{ actor.name }}</p>
                        <p class="is-6 has-text-grey">
                          {{ `@${actor.preferredUsername}` }}
                        </p>
                      </div>
                      <div class="media-content" v-else>
                        {{ `@${actor.preferredUsername}` }}
                      </div>
                    </div>
                  </b-checkbox>
                </p>
              </div>
              <div v-else class="content has-text-grey has-text-centered">
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
import { IActor, IGroup, IPerson } from "../../types/actor";
import OrganizerPicker from "./OrganizerPicker.vue";
import { PERSON_MEMBERSHIPS_WITH_MEMBERS } from "../../graphql/actor";
import { Paginate } from "../../types/paginate";

@Component({
  components: { OrganizerPicker },
  apollo: {
    groupMemberships: {
      query: PERSON_MEMBERSHIPS_WITH_MEMBERS,
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
export default class OrganizerPickerWrapper extends Vue {
  @Prop({ type: Object, required: true }) value!: IActor;

  @Prop({ default: true, type: Boolean }) inline!: boolean;

  @Prop({ type: Object, required: true }) identity!: IPerson;

  isComponentModalActive = false;

  currentActor: IActor = this.value;

  groupMemberships: Paginate<IMember> = { elements: [], total: 0 };

  @Prop({ type: Array, required: false, default: () => [] })
  contacts!: IActor[];

  actualContacts: (string | undefined)[] = this.contacts.map(({ id }) => id);

  @Watch("contacts")
  updateActualContacts(contacts: IActor[]): void {
    this.actualContacts = contacts.map(({ id }) => id);
  }

  @Watch("value")
  updateCurrentActor(value: IGroup): void {
    this.currentActor = value;
  }

  async relay(group: IGroup): Promise<void> {
    this.currentActor = group;
  }

  pickActor(): void {
    this.$emit(
      "update:contacts",
      this.actorMembersForCurrentActor.filter(({ id }) =>
        this.actualContacts.includes(id)
      )
    );
    this.$emit("input", this.currentActor);
    this.isComponentModalActive = false;
  }

  get actorMembersForCurrentActor(): IActor[] {
    const currentMembership = this.groupMemberships.elements.find(
      ({ parent: { id } }) => id === this.currentActor.id
    );
    if (currentMembership) {
      return currentMembership.parent.members.elements.map(
        ({ actor }: { actor: IActor }) => actor
      );
    }
    return [];
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
