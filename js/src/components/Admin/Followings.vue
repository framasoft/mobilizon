<template>
  <div>
    <form @submit="followRelay">
      <b-field
        :label="$t('Add an instance')"
        custom-class="add-relay"
        horizontal
      >
        <b-field grouped expanded size="is-large">
          <p class="control">
            <b-input
              v-model="newRelayAddress"
              :placeholder="$t('Ex: mobilizon.fr')"
            />
          </p>
          <p class="control">
            <b-button type="is-primary" native-type="submit">{{
              $t("Add an instance")
            }}</b-button>
          </p>
        </b-field>
      </b-field>
    </form>
    <b-table
      v-show="relayFollowings.elements.length > 0"
      :data="relayFollowings.elements"
      :loading="$apollo.queries.relayFollowings.loading"
      ref="table"
      :checked-rows.sync="checkedRows"
      :is-row-checkable="(row) => row.id !== 3"
      detailed
      :show-detail-icon="false"
      paginated
      backend-pagination
      :total="relayFollowings.total"
      :per-page="perPage"
      @page-change="onFollowingsPageChange"
      checkable
      checkbox-position="left"
    >
      <b-table-column
        field="targetActor.id"
        label="ID"
        width="40"
        numeric
        v-slot="props"
        >{{ props.row.targetActor.id }}</b-table-column
      >

      <b-table-column
        field="targetActor.type"
        :label="$t('Type')"
        width="80"
        v-slot="props"
      >
        <b-icon
          icon="lan"
          v-if="RelayMixin.isInstance(props.row.targetActor)"
        />
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

      <b-table-column field="targetActor.domain" :label="$t('Domain')" sortable>
        <template v-slot:default="props">
          <a
            @click="toggle(props.row)"
            v-if="RelayMixin.isInstance(props.row.targetActor)"
            >{{ props.row.targetActor.domain }}</a
          >
          <a @click="toggle(props.row)" v-else>{{
            `${props.row.targetActor.preferredUsername}@${props.row.targetActor.domain}`
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

      <template slot="detail" slot-scope="props">
        <article>
          <div class="content">
            <strong>{{ props.row.targetActor.name }}</strong>
            <small v-if="props.row.actor.preferredUsername !== 'relay'"
              >@{{ props.row.targetActor.preferredUsername }}</small
            >
            <p v-html="props.row.targetActor.summary" />
          </div>
        </article>
      </template>

      <template slot="bottom-left" v-if="checkedRows.length > 0">
        <b-button @click="removeRelays" type="is-danger">
          {{
            $tc(
              "No instance to remove|Remove instance|Remove {number} instances",
              checkedRows.length,
              { number: checkedRows.length }
            )
          }}
        </b-button>
      </template>
    </b-table>
    <b-message type="is-danger" v-if="relayFollowings.elements.length === 0">{{
      $t("You don't follow any instances yet.")
    }}</b-message>
  </div>
</template>
<script lang="ts">
import { Component, Mixins } from "vue-property-decorator";
import { SnackbarProgrammatic as Snackbar } from "buefy";
import { formatDistanceToNow } from "date-fns";
import { ADD_RELAY, REMOVE_RELAY } from "../../graphql/admin";
import { IFollower } from "../../types/actor/follower.model";
import RelayMixin from "../../mixins/relay";

@Component({
  metaInfo() {
    return {
      title: this.$t("Followings") as string,
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class Followings extends Mixins(RelayMixin) {
  newRelayAddress = "";

  RelayMixin = RelayMixin;

  formatDistanceToNow = formatDistanceToNow;

  async followRelay(e: Event): Promise<void> {
    e.preventDefault();
    try {
      await this.$apollo.mutate({
        mutation: ADD_RELAY,
        variables: {
          address: this.newRelayAddress.trim(), // trim to fix copy and paste domain name spaces and tabs
        },
      });
      await this.$apollo.queries.relayFollowings.refetch();
      this.newRelayAddress = "";
    } catch (err) {
      Snackbar.open({
        message: err.message,
        type: "is-danger",
        position: "is-bottom",
      });
    }
  }

  async removeRelays(): Promise<void> {
    await this.checkedRows.forEach((row: IFollower) => {
      this.removeRelay(
        `${row.targetActor.preferredUsername}@${row.targetActor.domain}`
      );
    });
  }

  async removeRelay(address: string): Promise<void> {
    try {
      await this.$apollo.mutate({
        mutation: REMOVE_RELAY,
        variables: {
          address,
        },
      });
      await this.$apollo.queries.relayFollowings.refetch();
      this.checkedRows = [];
    } catch (e) {
      Snackbar.open({
        message: e.message,
        type: "is-danger",
        position: "is-bottom",
      });
    }
  }
}
</script>
