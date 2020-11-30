<template>
  <main class="container">
    <section v-if="event">
      <nav class="breadcrumb" aria-label="breadcrumbs">
        <ul>
          <li>
            <router-link :to="{ name: RouteName.MY_EVENTS }">{{
              $t("My events")
            }}</router-link>
          </li>
          <li>
            <router-link
              :to="{
                name: RouteName.EVENT,
                params: { uuid: event.uuid },
              }"
              >{{ event.title }}</router-link
            >
          </li>
          <li class="is-active">
            <router-link
              :to="{
                name: RouteName.PARTICIPANTS,
                params: { uuid: event.uuid },
              }"
              >{{ $t("Participants") }}</router-link
            >
          </li>
        </ul>
      </nav>
      <h2 class="title">{{ $t("Participants") }}</h2>
      <b-field :label="$t('Status')" horizontal>
        <b-select v-model="roles">
          <option value="">
            {{ $t("Everything") }}
          </option>
          <option :value="ParticipantRole.CREATOR">
            {{ $t("Organizer") }}
          </option>
          <option :value="ParticipantRole.PARTICIPANT">
            {{ $t("Participant") }}
          </option>
          <option :value="ParticipantRole.NOT_APPROVED">
            {{ $t("Not approved") }}
          </option>
          <option :value="ParticipantRole.REJECTED">
            {{ $t("Rejected") }}
          </option>
        </b-select>
      </b-field>
      <b-table
        :data="event.participants.elements"
        ref="queueTable"
        detailed
        detail-key="id"
        :checked-rows.sync="checkedRows"
        checkable
        :is-row-checkable="(row) => row.role !== ParticipantRole.CREATOR"
        checkbox-position="left"
        :show-detail-icon="false"
        :loading="this.$apollo.loading"
        paginated
        backend-pagination
        :pagination-simple="true"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
        :total="event.participants.total"
        :per-page="PARTICIPANTS_PER_PAGE"
        backend-sorting
        :default-sort-direction="'desc'"
        :default-sort="['insertedAt', 'desc']"
        @page-change="(newPage) => (page = newPage)"
        @sort="(field, order) => $emit('sort', field, order)"
      >
        <b-table-column
          field="actor.preferredUsername"
          :label="$t('Participant')"
          v-slot="props"
        >
          <article class="media">
            <figure
              class="media-left image is-48x48"
              v-if="props.row.actor.avatar"
            >
              <img
                class="is-rounded"
                :src="props.row.actor.avatar.url"
                alt=""
              />
            </figure>
            <b-icon
              class="media-left"
              v-else-if="props.row.actor.preferredUsername === 'anonymous'"
              size="is-large"
              icon="incognito"
            />
            <b-icon
              class="media-left"
              v-else
              size="is-large"
              icon="account-circle"
            />
            <div class="media-content">
              <div class="content">
                <span v-if="props.row.actor.preferredUsername !== 'anonymous'">
                  <span v-if="props.row.actor.name">{{
                    props.row.actor.name
                  }}</span
                  ><br />
                  <span class="is-size-7 has-text-grey"
                    >@{{ usernameWithDomain(props.row.actor) }}</span
                  >
                </span>
                <span v-else>
                  {{ $t("Anonymous participant") }}
                </span>
              </div>
            </div>
          </article>
        </b-table-column>
        <b-table-column field="role" :label="$t('Role')" v-slot="props">
          <b-tag
            type="is-primary"
            v-if="props.row.role === ParticipantRole.CREATOR"
          >
            {{ $t("Organizer") }}
          </b-tag>
          <b-tag v-else-if="props.row.role === ParticipantRole.PARTICIPANT">
            {{ $t("Participant") }}
          </b-tag>
          <b-tag v-else-if="props.row.role === ParticipantRole.NOT_CONFIRMED">
            {{ $t("Not confirmed") }}
          </b-tag>
          <b-tag
            type="is-warning"
            v-else-if="props.row.role === ParticipantRole.NOT_APPROVED"
          >
            {{ $t("Not approved") }}
          </b-tag>
          <b-tag
            type="is-danger"
            v-else-if="props.row.role === ParticipantRole.REJECTED"
          >
            {{ $t("Rejected") }}
          </b-tag>
        </b-table-column>
        <b-table-column
          field="metadata.message"
          :label="$t('Message')"
          v-slot="props"
        >
          <span
            @click="toggleQueueDetails(props.row)"
            :class="{
              'ellipsed-message':
                props.row.metadata.message.length > MESSAGE_ELLIPSIS_LENGTH,
            }"
            v-if="props.row.metadata && props.row.metadata.message"
          >
            {{ props.row.metadata.message | ellipsize }}
          </span>
          <span v-else class="has-text-grey">
            {{ $t("No message") }}
          </span>
        </b-table-column>
        <b-table-column field="insertedAt" :label="$t('Date')" v-slot="props">
          <span class="has-text-centered">
            {{ props.row.insertedAt | formatDateString }}<br />{{
              props.row.insertedAt | formatTimeString
            }}
          </span>
        </b-table-column>
        <template slot="detail" slot-scope="props">
          <article v-html="nl2br(props.row.metadata.message)" />
        </template>
        <template slot="empty">
          <section class="section">
            <div class="content has-text-grey has-text-centered">
              <p>{{ $t("No participant matches the filters") }}</p>
            </div>
          </section>
        </template>
        <template slot="bottom-left">
          <div class="buttons">
            <b-button
              @click="acceptParticipants(checkedRows)"
              type="is-success"
              :disabled="!canAcceptParticipants"
            >
              {{
                $tc(
                  "No participant to approve|Approve participant|Approve {number} participants",
                  checkedRows.length,
                  { number: checkedRows.length }
                )
              }}
            </b-button>
            <b-button
              @click="refuseParticipants(checkedRows)"
              type="is-danger"
              :disabled="!canRefuseParticipants"
            >
              {{
                $tc(
                  "No participant to reject|Reject participant|Reject {number} participants",
                  checkedRows.length,
                  { number: checkedRows.length }
                )
              }}
            </b-button>
          </div>
        </template>
      </b-table>
    </section>
  </main>
</template>

<script lang="ts">
import { Component, Prop, Vue, Watch, Ref } from "vue-property-decorator";
import { ParticipantRole } from "@/types/enums";
import { IParticipant } from "../../types/participant.model";
import { IEvent, IEventParticipantStats } from "../../types/event.model";
import { PARTICIPANTS, UPDATE_PARTICIPANT } from "../../graphql/event";
import { CURRENT_ACTOR_CLIENT } from "../../graphql/actor";
import { IPerson, usernameWithDomain } from "../../types/actor";
import { CONFIG } from "../../graphql/config";
import { IConfig } from "../../types/config.model";
import { nl2br } from "../../utils/html";
import { asyncForEach } from "../../utils/asyncForEach";
import RouteName from "../../router/name";

const PARTICIPANTS_PER_PAGE = 10;
const MESSAGE_ELLIPSIS_LENGTH = 130;

@Component({
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
    config: CONFIG,
    event: {
      query: PARTICIPANTS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          uuid: this.eventId,
          page: 1,
          limit: PARTICIPANTS_PER_PAGE,
          roles: this.roles,
        };
      },
      skip() {
        return !this.currentActor.id;
      },
    },
  },
  filters: {
    ellipsize: (text?: string) =>
      text && text.substr(0, MESSAGE_ELLIPSIS_LENGTH).concat("…"),
  },
})
export default class Participants extends Vue {
  @Prop({ required: true }) eventId!: string;

  page = 1;

  limit = PARTICIPANTS_PER_PAGE;

  event!: IEvent;

  config!: IConfig;

  ParticipantRole = ParticipantRole;

  currentActor!: IPerson;

  PARTICIPANTS_PER_PAGE = PARTICIPANTS_PER_PAGE;

  checkedRows: IParticipant[] = [];

  roles: ParticipantRole = ParticipantRole.PARTICIPANT;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  @Ref("queueTable") readonly queueTable!: any;

  mounted(): void {
    const roleQuery = this.$route.query.role as string;
    if (Object.values(ParticipantRole).includes(roleQuery as ParticipantRole)) {
      this.roles = roleQuery as ParticipantRole;
    }
  }

  get participantStats(): IEventParticipantStats | null {
    if (!this.event) return null;
    return this.event.participantStats;
  }

  @Watch("page")
  loadMoreParticipants(): void {
    this.$apollo.queries.event.fetchMore({
      // New variables
      variables: {
        page: this.page,
        limit: this.limit,
      },
      // Transform the previous result with new data
      updateQuery: (previousResult, { fetchMoreResult }) => {
        const oldParticipants = previousResult.event.participants;
        const newParticipants = fetchMoreResult.event.participants;

        return {
          event: {
            ...previousResult.event,
            participants: {
              elements: [
                ...oldParticipants.elements,
                ...newParticipants.elements,
              ],
              total: newParticipants.total,
              __typename: oldParticipants.__typename,
            },
          },
        };
      },
    });
  }

  async acceptParticipant(participant: IParticipant): Promise<void> {
    try {
      await this.$apollo.mutate({
        mutation: UPDATE_PARTICIPANT,
        variables: {
          id: participant.id,
          role: ParticipantRole.PARTICIPANT,
        },
      });
    } catch (e) {
      console.error(e);
    }
  }

  async refuseParticipant(participant: IParticipant): Promise<void> {
    try {
      await this.$apollo.mutate({
        mutation: UPDATE_PARTICIPANT,
        variables: {
          id: participant.id,
          role: ParticipantRole.REJECTED,
        },
      });
    } catch (e) {
      console.error(e);
    }
  }

  async acceptParticipants(participants: IParticipant[]): Promise<void> {
    await asyncForEach(participants, async (participant: IParticipant) => {
      await this.acceptParticipant(participant);
    });
    this.checkedRows = [];
  }

  async refuseParticipants(participants: IParticipant[]): Promise<void> {
    await asyncForEach(participants, async (participant: IParticipant) => {
      await this.refuseParticipant(participant);
    });
    this.checkedRows = [];
  }

  /**
   * We can accept participants if at least one of them is not approved
   */
  get canAcceptParticipants(): boolean {
    return this.checkedRows.some((participant: IParticipant) =>
      [ParticipantRole.NOT_APPROVED, ParticipantRole.REJECTED].includes(
        participant.role
      )
    );
  }

  /**
   * We can refuse participants if at least one of them is something different than not approved
   */
  get canRefuseParticipants(): boolean {
    return this.checkedRows.some(
      (participant: IParticipant) =>
        participant.role !== ParticipantRole.REJECTED
    );
  }

  MESSAGE_ELLIPSIS_LENGTH = MESSAGE_ELLIPSIS_LENGTH;

  nl2br = nl2br;

  toggleQueueDetails(row: IParticipant): void {
    if (
      row.metadata.message &&
      row.metadata.message.length < MESSAGE_ELLIPSIS_LENGTH
    )
      return;
    this.queueTable.toggleDetails(row);
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
section {
  padding: 1rem 0;
}

.table {
  .ellipsed-message {
    cursor: pointer;
  }

  span.tag {
    &.is-primary {
      background-color: $primary;
    }
  }
}

nav.breadcrumb {
  a {
    text-decoration: none;
  }
}
</style>
