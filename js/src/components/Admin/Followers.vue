<template>
  <div>
    <b-table
      v-show="relayFollowers.elements.length > 0"
      :data="relayFollowers.elements"
      :loading="$apollo.queries.relayFollowers.loading"
      ref="table"
      :checked-rows.sync="checkedRows"
      detailed
      :show-detail-icon="false"
      paginated
      backend-pagination
      :current-page.sync="page"
      :aria-next-label="$t('Next page')"
      :aria-previous-label="$t('Previous page')"
      :aria-page-label="$t('Page')"
      :aria-current-label="$t('Current page')"
      :total="relayFollowers.total"
      :per-page="FOLLOWERS_PER_PAGE"
      @page-change="onFollowersPageChange"
      checkable
      checkbox-position="left"
    >
      <b-table-column
        field="actor.id"
        label="ID"
        width="40"
        numeric
        v-slot="props"
        >{{ props.row.actor.id }}</b-table-column
      >

      <b-table-column
        field="actor.type"
        :label="$t('Type')"
        width="80"
        v-slot="props"
      >
        <b-icon icon="lan" v-if="RelayMixin.isInstance(props.row.actor)" />
        <b-icon icon="account-circle" v-else />
      </b-table-column>

      <b-table-column
        field="approved"
        :label="$t('Status')"
        width="100"
        sortable
        centered
        v-slot="props"
      >
        <span
          :class="`tag ${props.row.approved ? 'is-success' : 'is-danger'}`"
          >{{ props.row.approved ? $t("Accepted") : $t("Pending") }}</span
        >
      </b-table-column>

      <b-table-column field="actor.domain" :label="$t('Domain')" sortable>
        <template v-slot:default="props">
          <a
            @click="toggle(props.row)"
            v-if="RelayMixin.isInstance(props.row.actor)"
            >{{ props.row.actor.domain }}</a
          >
          <a @click="toggle(props.row)" v-else>{{
            `${props.row.actor.preferredUsername}@${props.row.actor.domain}`
          }}</a>
        </template>
      </b-table-column>

      <b-table-column
        field="targetActor.updatedAt"
        :label="$t('Date')"
        sortable
        v-slot="props"
      >
        <span
          :title="$options.filters.formatDateTimeString(props.row.updatedAt)"
          >{{
            formatDistanceToNow(new Date(props.row.updatedAt), {
              locale: $dateFnsLocale,
            })
          }}</span
        ></b-table-column
      >

      <template #detail="props">
        <article>
          <div class="content">
            <strong>{{ props.row.actor.name }}</strong>
            <small v-if="props.row.actor.preferredUsername !== 'relay'"
              >@{{ props.row.actor.preferredUsername }}</small
            >
            <p v-html="props.row.actor.summary" />
          </div>
        </article>
      </template>

      <template slot="bottom-left" v-if="checkedRows.length > 0">
        <div class="buttons">
          <b-button
            @click="acceptRelays"
            type="is-success"
            v-if="checkedRowsHaveAtLeastOneToApprove"
          >
            {{
              $tc(
                "No instance to approve|Approve instance|Approve {number} instances",
                checkedRows.length,
                { number: checkedRows.length }
              )
            }}
          </b-button>
          <b-button @click="rejectRelays" type="is-danger">
            {{
              $tc(
                "No instance to reject|Reject instance|Reject {number} instances",
                checkedRows.length,
                { number: checkedRows.length }
              )
            }}
          </b-button>
        </div>
      </template>
    </b-table>
    <b-message type="is-danger" v-if="relayFollowers.elements.length === 0">{{
      $t("No instance follows your instance yet.")
    }}</b-message>
  </div>
</template>
<script lang="ts">
import { Component, Mixins } from "vue-property-decorator";
import { SnackbarProgrammatic as Snackbar } from "buefy";
import { formatDistanceToNow } from "date-fns";
import {
  ACCEPT_RELAY,
  REJECT_RELAY,
  RELAY_FOLLOWERS,
} from "../../graphql/admin";
import { IFollower } from "../../types/actor/follower.model";
import RelayMixin from "../../mixins/relay";
import RouteName from "@/router/name";
import { Paginate } from "@/types/paginate";

const FOLLOWERS_PER_PAGE = 10;

@Component({
  apollo: {
    relayFollowers: {
      query: RELAY_FOLLOWERS,
      variables() {
        return {
          page: this.page,
          limit: FOLLOWERS_PER_PAGE,
        };
      },
    },
  },
  metaInfo() {
    return {
      title: this.$t("Followers") as string,
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class Followers extends Mixins(RelayMixin) {
  RelayMixin = RelayMixin;

  formatDistanceToNow = formatDistanceToNow;

  relayFollowers: Paginate<IFollower> = { elements: [], total: 0 };

  checkedRows: IFollower[] = [];

  FOLLOWERS_PER_PAGE = FOLLOWERS_PER_PAGE;

  toggle(row: Record<string, unknown>): void {
    this.table.toggleDetails(row);
  }

  get page(): number {
    return parseInt((this.$route.query.page as string) || "1", 10);
  }

  set page(page: number) {
    this.pushRouter(RouteName.RELAY_FOLLOWERS, {
      page: page.toString(),
    });
  }

  acceptRelays(): void {
    this.checkedRows.forEach((row: IFollower) => {
      this.acceptRelay(`${row.actor.preferredUsername}@${row.actor.domain}`);
    });
  }

  rejectRelays(): void {
    this.checkedRows.forEach((row: IFollower) => {
      this.rejectRelay(`${row.actor.preferredUsername}@${row.actor.domain}`);
    });
  }

  async acceptRelay(address: string): Promise<void> {
    try {
      await this.$apollo.mutate({
        mutation: ACCEPT_RELAY,
        variables: {
          address,
        },
      });
      await this.$apollo.queries.relayFollowers.refetch();
      this.checkedRows = [];
    } catch (e) {
      Snackbar.open({
        message: e.message,
        type: "is-danger",
        position: "is-bottom",
      });
    }
  }

  async rejectRelay(address: string): Promise<void> {
    try {
      await this.$apollo.mutate({
        mutation: REJECT_RELAY,
        variables: {
          address,
        },
      });
      await this.$apollo.queries.relayFollowers.refetch();
      this.checkedRows = [];
    } catch (e) {
      Snackbar.open({
        message: e.message,
        type: "is-danger",
        position: "is-bottom",
      });
    }
  }

  get checkedRowsHaveAtLeastOneToApprove(): boolean {
    return this.checkedRows.some((checkedRow) => !checkedRow.approved);
  }

  async onFollowersPageChange(page: number): Promise<void> {
    this.page = page;
    try {
      await this.$apollo.queries.relayFollowers.fetchMore({
        variables: {
          page: this.page,
          limit: FOLLOWERS_PER_PAGE,
        },
      });
    } catch (err) {
      console.error(err);
    }
  }
}
</script>
