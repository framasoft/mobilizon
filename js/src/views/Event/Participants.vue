<template>
  <section class="section container" v-if="event">
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
    <h1 class="title">{{ $t("Participants") }}</h1>
    <div class="level">
      <div class="level-left">
        <div class="level-item">
          <b-field :label="$t('Status')" horizontal label-for="role-select">
            <b-select v-model="role" id="role-select">
              <option :value="null">
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
        </div>
        <div class="level-item" v-if="exportFormats.length > 0">
          <b-dropdown aria-role="list">
            <template #trigger="{ active }">
              <b-button
                :label="$t('Export')"
                type="is-primary"
                :icon-right="active ? 'menu-up' : 'menu-down'"
              />
            </template>

            <b-dropdown-item
              has-link
              v-for="format in exportFormats"
              :key="format"
              aria-role="listitem"
              @click="exportParticipants(format)"
              @keyup.enter="exportParticipants(format)"
            >
              <button class="dropdown-button">
                <b-icon :icon="formatToIcon(format)"></b-icon>
                {{ format }}
              </button>
            </b-dropdown-item>
          </b-dropdown>
        </div>
      </div>
    </div>
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
      :current-page="page"
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
            <img class="is-rounded" :src="props.row.actor.avatar.url" alt="" />
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
                <span class="is-size-7 has-text-grey-dark"
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
        class="column-message"
        :label="$t('Message')"
        v-slot="props"
      >
        <div
          @click="toggleQueueDetails(props.row)"
          :class="{
            'ellipsed-message':
              props.row.metadata.message.length > MESSAGE_ELLIPSIS_LENGTH,
          }"
          v-if="props.row.metadata && props.row.metadata.message"
        >
          <p v-if="props.row.metadata.message.length > MESSAGE_ELLIPSIS_LENGTH">
            {{ props.row.metadata.message | ellipsize }}
          </p>
          <p v-else>
            {{ props.row.metadata.message }}
          </p>
          <button
            type="button"
            class="button is-text"
            v-if="props.row.metadata.message.length > MESSAGE_ELLIPSIS_LENGTH"
            @click.stop="toggleQueueDetails(props.row)"
          >
            {{
              openDetailedRows[props.row.id] ? $t("View less") : $t("View more")
            }}
          </button>
        </div>
        <p v-else class="has-text-grey-dark">
          {{ $t("No message") }}
        </p>
      </b-table-column>
      <b-table-column field="insertedAt" :label="$t('Date')" v-slot="props">
        <span class="has-text-centered">
          {{ props.row.insertedAt | formatDateString }}<br />{{
            props.row.insertedAt | formatTimeString
          }}
        </span>
      </b-table-column>
      <template #detail="props">
        <article v-html="nl2br(props.row.metadata.message)" />
      </template>
      <template slot="empty">
        <section class="section">
          <div class="content has-text-grey-dark has-text-centered">
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
</template>

<script lang="ts">
import { Component, Prop, Vue, Ref } from "vue-property-decorator";
import { ParticipantRole } from "@/types/enums";
import { IParticipant } from "../../types/participant.model";
import { IEvent, IEventParticipantStats } from "../../types/event.model";
import {
  EXPORT_EVENT_PARTICIPATIONS,
  PARTICIPANTS,
  UPDATE_PARTICIPANT,
} from "../../graphql/event";
import { CURRENT_ACTOR_CLIENT } from "../../graphql/actor";
import { IPerson, usernameWithDomain } from "../../types/actor";
import { EVENT_PARTICIPANTS } from "../../graphql/config";
import { IConfig } from "../../types/config.model";
import { nl2br } from "../../utils/html";
import { asyncForEach } from "../../utils/asyncForEach";
import RouteName from "../../router/name";
import VueRouter from "vue-router";
const { isNavigationFailure, NavigationFailureType } = VueRouter;

const PARTICIPANTS_PER_PAGE = 10;
const MESSAGE_ELLIPSIS_LENGTH = 130;

type exportFormat = "CSV" | "PDF" | "ODS";

@Component({
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
    config: EVENT_PARTICIPANTS,
    event: {
      query: PARTICIPANTS,
      variables() {
        return {
          uuid: this.eventId,
          page: this.page,
          limit: PARTICIPANTS_PER_PAGE,
          roles: this.role,
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
  metaInfo() {
    return {
      title: this.$t("Participants") as string,
    };
  },
})
export default class Participants extends Vue {
  @Prop({ required: true }) eventId!: string;

  get page(): number {
    return parseInt((this.$route.query.page as string) || "1", 10);
  }

  set page(page: number) {
    this.pushRouter(RouteName.PARTICIPATIONS, {
      page: page.toString(),
    });
  }

  get role(): ParticipantRole | null {
    if (
      Object.values(ParticipantRole).includes(
        this.$route.query.role as ParticipantRole
      )
    ) {
      return this.$route.query.role as ParticipantRole;
    }
    return null;
  }

  set role(role: ParticipantRole | null) {
    this.pushRouter(RouteName.PARTICIPATIONS, {
      role: role || "",
    });
  }

  limit = PARTICIPANTS_PER_PAGE;

  event!: IEvent;

  config!: IConfig;

  ParticipantRole = ParticipantRole;

  currentActor!: IPerson;

  PARTICIPANTS_PER_PAGE = PARTICIPANTS_PER_PAGE;

  checkedRows: IParticipant[] = [];

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  @Ref("queueTable") readonly queueTable!: any;

  get participantStats(): IEventParticipantStats | null {
    if (!this.event) return null;
    return this.event.participantStats;
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

  async exportParticipants(type: exportFormat): Promise<void> {
    try {
      const {
        data: { exportEventParticipants },
      } = await this.$apollo.mutate({
        mutation: EXPORT_EVENT_PARTICIPATIONS,
        variables: {
          eventId: this.event.id,
          format: type,
        },
      });
      const link =
        window.origin +
        "/exports/" +
        type.toLowerCase() +
        "/" +
        exportEventParticipants;
      console.log(link);
      const a = document.createElement("a");
      a.style.display = "none";
      document.body.appendChild(a);
      a.href = link;
      a.setAttribute("download", "true");
      a.click();
      window.URL.revokeObjectURL(a.href);
      document.body.removeChild(a);
    } catch (e: any) {
      console.error(e);
      if (e.graphQLErrors && e.graphQLErrors.length > 0) {
        this.$notifier.error(e.graphQLErrors[0].message);
      }
    }
  }

  get exportFormats(): string[] {
    return (this.config?.exportFormats?.eventParticipants || []).map((key) =>
      key.toUpperCase()
    );
  }

  formatToIcon(format: exportFormat): string {
    switch (format) {
      case "CSV":
        return "file-delimited";
      case "PDF":
        return "file-pdf-box";
      case "ODS":
        return "google-spreadsheet";
    }
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
    if (row.id) {
      this.openDetailedRows[row.id] = !this.openDetailedRows[row.id];
    }
  }

  openDetailedRows: Record<string, boolean> = {};

  async pushRouter(
    routeName: string,
    args: Record<string, string>
  ): Promise<void> {
    try {
      await this.$router.push({
        name: routeName,
        query: { ...this.$route.query, ...args },
      });
      this.$apollo.queries.event.refetch();
    } catch (e) {
      if (isNavigationFailure(e, NavigationFailureType.redirected)) {
        throw Error(e.toString());
      }
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
section.container.container {
  padding: 1rem;
  background: $white;
}

.table {
  .column-message {
    vertical-align: middle;
  }
  .ellipsed-message {
    cursor: pointer;
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    justify-content: center;

    p {
      flex: 1;
      min-width: 200px;
    }

    button {
      display: inline;
    }
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

button.dropdown-button {
  &:hover {
    background-color: #f5f5f5;
    color: #0a0a0a;
  }
  width: 100%;
  display: flex;
  flex: 1;
  background: white;
  border: none;
  cursor: pointer;
  color: #4a4a4a;
  font-size: 0.875rem;
  line-height: 1.5;
  padding: 0.375rem 1rem;
}
</style>
