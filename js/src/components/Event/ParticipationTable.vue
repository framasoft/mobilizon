<template>
  <b-table
    :data="data"
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
    :aria-next-label="$t('Next page')"
    :aria-previous-label="$t('Previous page')"
    :aria-page-label="$t('Page')"
    :aria-current-label="$t('Current page')"
    :total="total"
    :per-page="perPage"
    backend-sorting
    :default-sort-direction="'desc'"
    :default-sort="['insertedAt', 'desc']"
    @page-change="(page) => $emit('page-change', page)"
    @sort="(field, order) => $emit('sort', field, order)"
  >
    <template slot-scope="props">
      <b-table-column field="insertedAt" :label="$t('Date')" sortable>
        <b-tag type="is-success" class="has-text-centered"
          >{{ props.row.insertedAt | formatDateString }}<br />{{
            props.row.insertedAt | formatTimeString
          }}</b-tag
        >
      </b-table-column>
      <b-table-column field="role" :label="$t('Role')" sortable v-if="showRole">
        <span v-if="props.row.role === ParticipantRole.CREATOR">
          {{ $t("Organizer") }}
        </span>
        <span v-else-if="props.row.role === ParticipantRole.PARTICIPANT">
          {{ $t("Participant") }}
        </span>
      </b-table-column>
      <b-table-column field="actor.preferredUsername" :label="$t('Participant')" sortable>
        <article class="media">
          <figure class="media-left" v-if="props.row.actor.avatar">
            <p class="image is-48x48">
              <img :src="props.row.actor.avatar.url" alt="" />
            </p>
          </figure>
          <b-icon
            class="media-left"
            v-else-if="props.row.actor.preferredUsername === 'anonymous'"
            size="is-large"
            icon="incognito"
          />
          <b-icon class="media-left" v-else size="is-large" icon="account-circle" />
          <div class="media-content">
            <div class="content">
              <span v-if="props.row.actor.preferredUsername !== 'anonymous'">
                <span v-if="props.row.actor.name">{{ props.row.actor.name }}</span
                ><br />
                <span class="is-size-7 has-text-grey"
                  >@{{ props.row.actor.preferredUsername }}</span
                >
              </span>
              <span v-else>
                {{ $t("Anonymous participant") }}
              </span>
            </div>
          </div>
        </article>
      </b-table-column>
      <b-table-column field="metadata.message" :label="$t('Message')">
        <span
          @click="toggleQueueDetails(props.row)"
          :class="{
            'ellipsed-message': props.row.metadata.message.length > MESSAGE_ELLIPSIS_LENGTH,
          }"
          v-if="props.row.metadata && props.row.metadata.message"
        >
          {{ props.row.metadata.message | ellipsize }}
        </span>
        <span v-else class="has-text-grey">
          {{ $t("No message") }}
        </span>
      </b-table-column>
    </template>
    <template slot="detail" slot-scope="props">
      <article v-html="nl2br(props.row.metadata.message)" />
    </template>
    <template slot="bottom-left" v-if="checkedRows.length > 0">
      <div class="buttons">
        <b-button
          @click="acceptParticipants(checkedRows)"
          type="is-success"
          v-if="canAcceptParticipants"
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
          v-if="canRefuseParticipants"
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
</template>
<script lang="ts">
import { Component, Prop, Vue, Ref } from "vue-property-decorator";
import { IParticipant, ParticipantRole } from "../../types/event.model";
import { nl2br } from "../../utils/html";
import { asyncForEach } from "../../utils/asyncForEach";

const MESSAGE_ELLIPSIS_LENGTH = 130;

@Component({
  filters: {
    ellipsize: (text?: string) => text && text.substr(0, MESSAGE_ELLIPSIS_LENGTH).concat("…"),
  },
})
export default class ParticipationTable extends Vue {
  @Prop({ required: true, type: Array }) data!: IParticipant[];

  @Prop({ required: true, type: Number }) total!: number;

  @Prop({ required: true, type: Function }) acceptParticipant!: Function;

  @Prop({ required: true, type: Function }) refuseParticipant!: Function;

  @Prop({ required: false, type: Boolean, default: false }) showRole!: boolean;

  @Prop({ required: false, type: Number, default: 20 }) perPage!: number;

  @Ref("queueTable") readonly queueTable!: any;

  checkedRows: IParticipant[] = [];

  MESSAGE_ELLIPSIS_LENGTH = MESSAGE_ELLIPSIS_LENGTH;

  nl2br = nl2br;

  ParticipantRole = ParticipantRole;

  toggleQueueDetails(row: IParticipant) {
    if (row.metadata.message && row.metadata.message.length < MESSAGE_ELLIPSIS_LENGTH) return;
    this.queueTable.toggleDetails(row);
  }

  async acceptParticipants(participants: IParticipant[]) {
    await asyncForEach(participants, async (participant: IParticipant) => {
      await this.acceptParticipant(participant);
    });
    this.checkedRows = [];
  }

  async refuseParticipants(participants: IParticipant[]) {
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
      [ParticipantRole.NOT_APPROVED, ParticipantRole.REJECTED].includes(participant.role)
    );
  }

  /**
   * We can refuse participants if at least one of them is something different than not approved
   */
  get canRefuseParticipants(): boolean {
    return this.checkedRows.some(
      (participant: IParticipant) => participant.role !== ParticipantRole.REJECTED
    );
  }
}
</script>
<style lang="scss" scoped>
.ellipsed-message {
  cursor: pointer;
}

.table {
  span.tag {
    height: initial;
  }
}
</style>
