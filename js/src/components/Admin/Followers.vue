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
                :total="relayFollowers.total"
                :per-page="perPage"
                @page-change="onPageChange"
                checkable
                checkbox-position="left">
            <template slot-scope="props">
                <b-table-column field="actor.id" label="ID" width="40" numeric>
                    {{ props.row.actor.id }}
                </b-table-column>

                <b-table-column field="actor.type" :label="$t('Type')" width="80">
                    <b-icon icon="lan" v-if="isInstance(props.row.actor)" />
                    <b-icon icon="account-circle" v-else />
                </b-table-column>

                <b-table-column field="approved" :label="$t('Status')" width="100" sortable centered>
                            <span :class="`tag ${props.row.approved ? 'is-success' : 'is-danger' }`">
                               {{ props.row.approved ? $t('Accepted') : $t('Pending') }}
                            </span>
                </b-table-column>

                <b-table-column field="actor.domain" :label="$t('Domain')" sortable>
                    <template>
                        <a @click="toggle(props.row)" v-if="isInstance(props.row.actor)">
                            {{ props.row.actor.domain }}
                        </a>
                        <a @click="toggle(props.row)" v-else>
                            {{ `${props.row.actor.preferredUsername}@${props.row.actor.domain}` }}
                        </a>
                    </template>
                </b-table-column>

                <b-table-column field="actor.updatedAt" :label="$t('Date')" sortable>
                    {{ props.row.updatedAt | formatDateTimeString }}
                </b-table-column>
            </template>

            <template slot="detail" slot-scope="props">
                <article>
                    <div class="content">
                        <strong>{{ props.row.actor.domain }}</strong>
                        <small>@{{ props.row.actor.preferredUsername }}</small>
                        <small>31m</small>
                        <br>
                        <p v-html="props.row.actor.summary" />
                    </div>
                </article>
            </template>

            <template slot="bottom-left" v-if="checkedRows.length > 0">
                <div class="buttons">
                    <b-button @click="acceptRelays" type="is-success" v-if="checkedRowsHaveAtLeastOneToApprove">
                        {{ $tc('No instance to approve|Approve instance|Approve {number} instances', checkedRows.length, { number: checkedRows.length }) }}
                    </b-button>
                    <b-button @click="rejectRelays" type="is-danger">
                        {{ $tc('No instance to reject|Reject instance|Reject {number} instances', checkedRows.length, { number: checkedRows.length }) }}
                    </b-button>
                </div>
            </template>
        </b-table>
        <b-message type="is-danger" v-if="relayFollowers.elements.length === 0">
            {{ $t("No instance follows your instance yet.") }}
        </b-message>
    </div>
</template>
<script lang="ts">
import { Component, Mixins } from 'vue-property-decorator';
import { ACCEPT_RELAY, REJECT_RELAY, RELAY_FOLLOWERS } from '@/graphql/admin';
import { Paginate } from '@/types/paginate';
import { IFollower } from '@/types/actor/follower.model';
import RelayMixin from '@/mixins/relay';

@Component({
  apollo: {
    relayFollowers: {
      query: RELAY_FOLLOWERS,
      fetchPolicy: 'cache-and-network',
    },
  },
  metaInfo() {
    return {
      title: this.$t('Followers') as string,
      titleTemplate: '%s | Mobilizon',
    };
  },
})
export default class Followers extends Mixins(RelayMixin) {
  relayFollowers: Paginate<IFollower> = { elements: [], total: 0 };

  async acceptRelays() {
    await this.checkedRows.forEach((row: IFollower) => {
      this.acceptRelay(`${row.actor.preferredUsername}@${row.actor.domain}`);
    });
  }

  async rejectRelays() {
    await this.checkedRows.forEach((row: IFollower) => {
      this.rejectRelay(`${row.actor.preferredUsername}@${row.actor.domain}`);
    });
  }

  async acceptRelay(address: String) {
    await this.$apollo.mutate({
      mutation: ACCEPT_RELAY,
      variables: {
        address,
      },
    });
    await this.$apollo.queries.relayFollowers.refetch();
    this.checkedRows = [];
  }

  async rejectRelay(address: String) {
    await this.$apollo.mutate({
      mutation: REJECT_RELAY,
      variables: {
        address,
      },
    });
    await this.$apollo.queries.relayFollowers.refetch();
    this.checkedRows = [];
  }

  get checkedRowsHaveAtLeastOneToApprove(): boolean {
    return this.checkedRows.some(checkedRow => !checkedRow.approved);
  }
}
</script>